--------------------------------------------------------------------------------
-- Copyright (c) 2013, Felix Krause <contact@flyx.org>
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--------------------------------------------------------------------------------

with Ada.Text_IO;

with Interfaces.C.Strings;

with CL.API;
with CL.Enumerations;
with CL.Helpers;

package body CL.Programs is

   -----------------------------------------------------------------------------
   --  Helpers
   -----------------------------------------------------------------------------

   procedure Build_Callback_Dispatcher (Subject  : System.Address;
                                        Callback : Build_Callback);
   pragma Convention (C, Build_Callback_Dispatcher);

   procedure Build_Callback_Dispatcher (Subject  : System.Address;
                                        Callback : Build_Callback) is
   begin
      --  The callback receives a borrowed cl_program. Balance finalization of
      --  the temporary Ada wrapper with an explicit retain.
      Helpers.Error_Handler (API.Retain_Program (Subject));
      Callback (Program'(Ada.Finalization.Controlled with Location => Subject));
   end Build_Callback_Dispatcher;

   function String_Info is
     new Helpers.Get_Parameters (Return_Element_T => Character,
                                 Return_T         => String,
                                 Parameter_T      => Enumerations.Program_Info,
                                 C_Getter         => API.Get_Program_Info);

   function String_Build_Info is
     new Helpers.Get_Parameters2 (Return_Element_T => Character,
                                  Return_T         => String,
                                  Parameter_T      => Enumerations.Program_Build_Info,
                                  C_Getter         => API.Get_Program_Build_Info);

   -----------------------------------------------------------------------------
   --  Implementations
   -----------------------------------------------------------------------------

   package body Constructors is
      
      function Create_From_Source (Context : Contexts.Context'Class;
                                   Source : String) return Program is
         C_String    : aliased IFC.Strings.chars_ptr
           := IFC.Strings.New_String (Source);
         String_Size : aliased Size := Source'Length;
         Ret_Program : System.Address;
         Error       : aliased Enumerations.Error_Code;
      begin
         Ret_Program
           := API.Create_Program_With_Source 
             (Context => CL_Object (Context).Location,
              Count   => 1, 
              Sources => C_String'Access,
              Lengths => String_Size'Access,
              Error   => Error'Unchecked_Access);
         IFC.Strings.Free (C_String);
         Helpers.Error_Handler (Error => Error);
         return Program'(Ada.Finalization.Controlled with Location => Ret_Program);
      end Create_From_Source;

      function Create_From_Source (Context : Contexts.Context'Class;
                                   Sources : String_List)
                                   return Program is
         C_Strings   : array (Sources.First_Index .. Sources.Last_Index)
           of aliased IFC.Strings.chars_ptr;
         Size_List   : array (C_Strings'Range) of aliased Size;
         Ret_Program : System.Address;
         Error       : aliased Enumerations.Error_Code;
      begin
         for Index in C_Strings'Range loop
            C_Strings (Index) := IFC.Strings.New_String (Sources.Element (Index));
            Size_List (Index) := Size (IFC.Strings.Strlen (Item => C_Strings (Index)));
         end loop;

         Ret_Program := 
           API.Create_Program_With_Source (Context => CL_Object (Context).Location,
                                           Count => UInt (Size_List'Length),
                                           Sources => C_Strings (C_Strings'First)'Access,
                                           Lengths => Size_List (Size_List'First)'Access,
                                           Error => Error'Unchecked_Access);
         for Index in C_Strings'Range loop
            IFC.Strings.Free (C_Strings (Index));
         end loop;
         Helpers.Error_Handler (Error);
         return Program'(Ada.Finalization.Controlled with Location => Ret_Program);
      end Create_From_Source;
      
      
      function Create_From_Files (Context : Contexts.Context'Class;
                                  Sources : String_List)
                                  return Program is
         C_Strings   : array (Sources.First_Index .. Sources.Last_Index)
           of aliased IFC.Strings.chars_ptr;
         Size_List   : array (C_Strings'Range) of aliased Size;          
         Ret_Program : System.Address;
         Error       : aliased Enumerations.Error_Code;
      begin
         for Index in C_Strings'Range loop
            declare
               File : Ada.Text_IO.File_Type;
            begin
               Ada.Text_IO.Open (File => File, 
                                 Mode => Ada.Text_IO.In_File, 
                                 Name => Sources.Element (Index));
               C_Strings (Index) := IFC.Strings.New_String
                 (Helpers.Read_File (File));
               Ada.Text_IO.Close (File);
            end;
            Size_List (Index) := Size (IFC.Strings.Strlen (C_Strings (Index)));
         end loop;
         
         Ret_Program
           := API.Create_Program_With_Source (Context => CL_Object (Context).Location,
                                              Count => UInt (Size_List'Length),
                                              Sources => C_Strings (C_Strings'First)'Access,
                                              Lengths => Size_List (Size_List'First)'Access,
                                              Error => Error'Unchecked_Access);
         for Index in C_Strings'Range loop
            IFC.Strings.Free (C_Strings (Index));
         end loop;
         Helpers.Error_Handler (Error);
         return Program'(Ada.Finalization.Controlled with Location => Ret_Program);
      end Create_From_Files;
      

      function Create_From_Built_In_Kernels
        (Context      : Contexts.Context'Class;
         Devices      : Platforms.Device_List;
         Kernel_Names : String) return Program
      is
         function Raw_Device_List is
           new Helpers.Raw_List (Platforms.Device, Platforms.Device_List);
         Raw_Devices : Address_List := Raw_Device_List (Devices);
         C_Names     : IFC.Strings.chars_ptr :=
           IFC.Strings.New_String (Kernel_Names);
         Error       : aliased Enumerations.Error_Code;
         Raw_Program : System.Address;
      begin
         Raw_Program := API.Create_Program_With_Built_In_Kernels
           (Context      => CL_Object (Context).Location, 
            Num_Devices  => UInt (Raw_Devices'Length),
            Devices      => Raw_Devices (Raw_Devices'First)'Address, 
            Kernel_Names => C_Names,
            Error        => Error'Unchecked_Access);
         IFC.Strings.Free (C_Names);
         Helpers.Error_Handler (Error);
         return Program'(Ada.Finalization.Controlled with
                         Location => Raw_Program);
      end Create_From_Built_In_Kernels;

       function Create_From_Binary (Context  : Contexts.Context'Class;
                                    Devices  : Platforms.Device_List;
                                    Binaries : Binary_List;
                                    Success  : access Bool_List)
                                    return Program is
          function Raw_Device_List is
            new Helpers.Raw_List (Platforms.Device, Platforms.Device_List);

          Binary_Pointers : array (Binaries'Range) of aliased System.Address;
          Size_List       : array (Binaries'Range) of aliased Size;
          Status          : array (Binaries'Range) of aliased Int;
          Raw_Devices     : Address_List := Raw_Device_List (Devices);
          Ret_Program     : System.Address;
          Error           : aliased Enumerations.Error_Code;
       begin
          if Binaries'Length /= Devices'Length then
             raise Constraint_Error with
               "Devices and Binaries must have equal lengths";
          end if;

          if Success /= null
            and then (Success.all'First > Binaries'First
                      or else Success.all'Last < Binaries'Last)
          then
             raise CL.Invalid_Arg_Size with
               "Success must cover every Binaries index";
          end if;
         for Index in Binaries'Range loop
            Binary_Pointers (Index) := Binaries (Index) (Binaries (Index)'First)'Address;
            Size_List       (Index) := Binaries (Index)'Length;
         end loop;

          Ret_Program
            := API.Create_Program_With_Binary
              (Context     => CL_Object (Context).Location,
               Num_Devices => UInt (Raw_Devices'Length),
               Devices     => Raw_Devices (Raw_Devices'First)'Address,
               Lengths     => Size_List (Size_List'First)'Unchecked_Access,
               Binaries    => Binary_Pointers (Binary_Pointers'First)'Access,
               Status      => Status (Status'First)'Access,
               Error       => Error'Unchecked_Access);

          if Success /= null then
             for Index in Binaries'Range loop
                Success.all (Index) := (Status (Index) = 0);
             end loop;
          else
             Helpers.Error_Handler (Error);
          end if;
         return Program'(Ada.Finalization.Controlled with Location => Ret_Program);
      end Create_From_Binary;

   end Constructors;

   overriding procedure Adjust (Object : in out Program) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Retain_Program (Object.Location));
      end if;
   end Adjust;

   overriding procedure Finalize (Object : in out Program) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Release_Program (Object.Location));
      end if;
   end Finalize;

   procedure Build (Source   : Program;
                    Devices  : Platforms.Device_List;
                    Options  : String := "";
                    Callback : Build_Callback := null) is
      function Raw_Device_List is
        new Helpers.Raw_List (Platforms.Device, Platforms.Device_List);

       Error     : Enumerations.Error_Code;
       Raw_List  : Address_List := Raw_Device_List (Devices);
       C_Options : IFC.Strings.chars_ptr := IFC.Strings.New_String (Options);
    begin
       if Callback /= null then
          Error := API.Build_Program (Target      => Source.Location, 
                                      Num_Devices => UInt (Raw_List'Length),
                                      Device_List => Raw_List (1)'Address, 
                                      Options     => C_Options,
                                      Callback    => Build_Callback_Dispatcher'Access,
                                      User_Data   => Callback);
       else
          Error := API.Build_Program (Target      => Source.Location, 
                                      Num_Devices => UInt (Raw_List'Length),
                                      Device_List => Raw_List (1)'Address, 
                                      Options     => C_Options,
                                      Callback    => null, 
                                      User_Data   => null);
       end if;
       IFC.Strings.Free (C_Options);
       Helpers.Error_Handler (Error);
   end Build;

   procedure Compile
     (Source        : Program;
      Devices       : Platforms.Device_List;
      Options       : String := "";
      Input_Headers : Program_List := [1 .. 0 => <>];
      Header_Names  : String_List := String_Vectors.Empty_Vector;
      Callback      : Build_Callback := null)
   is
      function Raw_Device_List is
        new Helpers.Raw_List (Platforms.Device, Platforms.Device_List);
      function Raw_Program_List is
        new Helpers.Raw_List (Program, Program_List);

      Raw_Devices : Address_List := Raw_Device_List (Devices);
      Raw_Headers : Address_List := Raw_Program_List (Input_Headers);
      C_Options   : IFC.Strings.chars_ptr := IFC.Strings.New_String (Options);
      Error       : Enumerations.Error_Code;
   begin
      if Natural (Header_Names.Length) /= Input_Headers'Length then
         IFC.Strings.Free (Item => C_Options);
         raise Constraint_Error with
           "Input_Headers and Header_Names must have equal lengths";
      end if;

      if Input_Headers'Length = 0 then
         if Callback = null then
            Error := API.Compile_Program
              (Target               => Source.Location, 
               Num_Devices          => UInt (Raw_Devices'Length),
               Devices              => Raw_Devices (Raw_Devices'First)'Address, 
               Options              => C_Options, 
               Num_Input_Headers    => 0,
               Input_Headers        => System.Null_Address, 
               Header_Include_Names => System.Null_Address, 
               Callback             => null, 
               User_Data            => null);
         else
            Error := API.Compile_Program
              (Target               => Source.Location, 
               Num_Devices          => UInt (Raw_Devices'Length),
               Devices              => Raw_Devices (Raw_Devices'First)'Address, 
               Options              => C_Options, 
               Num_Input_Headers    => 0,
               Input_Headers        => System.Null_Address, 
               Header_Include_Names => System.Null_Address,
               Callback             => Build_Callback_Dispatcher'Access, 
               User_Data            => Callback);
         end if;
      else
         declare
            C_Names : array (Input_Headers'Range) of
              aliased IFC.Strings.chars_ptr;
         begin
            for Index in Input_Headers'Range loop
               C_Names (Index) := IFC.Strings.New_String
                 (Str => Header_Names.Element
                    (Index => Header_Names.First_Index +
                     (Index - Input_Headers'First)));
            end loop;

            if Callback = null then
               Error := API.Compile_Program
                 (Target               => Source.Location, 
                  Num_Devices          => UInt (Raw_Devices'Length),
                  Devices              => Raw_Devices (Raw_Devices'First)'Address, 
                  Options              => C_Options, 
                  Num_Input_Headers    => UInt (Raw_Headers'Length),
                  Input_Headers        => Raw_Headers (Raw_Headers'First)'Address,
                  Header_Include_Names => C_Names (C_Names'First)'Address, 
                  Callback             => null, 
                  User_Data            => null);
            else
               Error := API.Compile_Program
                 (Target               => Source.Location, 
                  Num_Devices          => UInt (Raw_Devices'Length),
                  Devices              => Raw_Devices (Raw_Devices'First)'Address, 
                  Options              => C_Options, 
                  Num_Input_Headers    => UInt (Raw_Headers'Length),
                  Input_Headers        => Raw_Headers (Raw_Headers'First)'Address,
                  Header_Include_Names => C_Names (C_Names'First)'Address,
                  Callback             => Build_Callback_Dispatcher'Access, 
                  User_Data            => Callback);
            end if;

            for Name of C_Names loop
               IFC.Strings.Free (Name);
            end loop;
         end;
      end if;

      IFC.Strings.Free (C_Options);
      Helpers.Error_Handler (Error);
   end Compile;

   function Link
     (Context        : Contexts.Context'Class;
      Devices        : Platforms.Device_List;
      Input_Programs : Program_List;
      Options        : String := "";
      Callback       : Build_Callback := null) return Program
   is
      function Raw_Device_List is
        new Helpers.Raw_List (Platforms.Device, Platforms.Device_List);
      function Raw_Program_List is
        new Helpers.Raw_List (Program, Program_List);

      Raw_Devices  : Address_List := Raw_Device_List (Devices);
      Raw_Programs : Address_List := Raw_Program_List (Input_Programs);
      C_Options    : IFC.Strings.chars_ptr := IFC.Strings.New_String (Options);
      Error        : aliased Enumerations.Error_Code;
      Raw_Program  : System.Address;
   begin
      if Callback = null then
         Raw_Program := API.Link_Program
           (Context            => CL_Object (Context).Location, 
            Num_Devices        => UInt (Raw_Devices'Length),
            Devices            => Raw_Devices (Raw_Devices'First)'Address, 
            Options            => C_Options,
            Num_Input_Programs => UInt (Raw_Programs'Length), 
            Input_Programs     => Raw_Programs (Raw_Programs'First)'Address,
            Callback           => null, 
            User_Data          => null, 
            Error              => Error'Unchecked_Access);
      else
         Raw_Program := API.Link_Program
           (Context            => CL_Object (Context).Location, 
            Num_Devices        => UInt (Raw_Devices'Length),
            Devices            => Raw_Devices (Raw_Devices'First)'Address, 
            Options            => C_Options,
            Num_Input_Programs => UInt (Raw_Programs'Length), 
            Input_Programs     => Raw_Programs (Raw_Programs'First)'Address,
            Callback           => Build_Callback_Dispatcher'Access, 
            User_Data          => Callback,
            Error              => Error'Unchecked_Access);
      end if;
      IFC.Strings.Free (C_Options);
      Helpers.Error_Handler (Error);
      return Program'(Ada.Finalization.Controlled with Location => Raw_Program);
   end Link;

   function Reference_Count (Source : Program) return UInt is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => UInt,
                                   Parameter_T => Enumerations.Program_Info,
                                   C_Getter    => API.Get_Program_Info);
   begin
      return Getter (Source, Enumerations.Reference_Count);
   end Reference_Count;

   function Context (Source : Program) return Contexts.Context is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Program_Info,
                                   C_Getter    => API.Get_Program_Info);
      function New_Context_Reference is
         new Helpers.New_Reference (Object_T => Contexts.Context);
   begin
      return New_Context_Reference (Getter (Source, Enumerations.Context));
   end Context;

   function Devices (Source : Program) return Platforms.Device_List is
      function Getter is
        new Helpers.Get_Parameters (Return_Element_T => System.Address,
                                    Return_T         => Address_List,
                                    Parameter_T      => Enumerations.Program_Info,
                                    C_Getter         => API.Get_Program_Info);
      Raw_List : constant Address_List := Getter (Source, Enumerations.Devices);
      Ret_List : Platforms.Device_List (Raw_List'Range);
   begin
       for Index in Raw_List'Range loop
          Ret_List (Index) :=
            Platforms.Raw_Interop.Wrap_Device (Location => Raw_List (Index));
       end loop;
      return Ret_List;
   end Devices;

   function Source (Source : Program) return String is
   begin
      return String_Info (Source, Enumerations.Source_String);
   end Source;

   function Number_Of_Kernels (Source : Program) return Size is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Size,
                                   Parameter_T => Enumerations.Program_Info,
                                   C_Getter    => API.Get_Program_Info);
   begin
      return Getter (Source, Enumerations.Num_Kernels);
   end Number_Of_Kernels;

   function Kernel_Names (Source : Program) return String is
   begin
      return String_Info (Source, Enumerations.Kernel_Names);
   end Kernel_Names;

   function Binaries (Source : Program) return Binary_List is
      Device_Count : constant Positive := Positive (Devices (Source => Source)'Length);
      Sizes        : aliased array (1 .. Device_Count) of Size;
      Error        : Enumerations.Error_Code;
   begin
      Error := API.Get_Program_Info
        (Source      => Source.Location, 
         Param       => Enumerations.Binary_Sizes,
         Value_Size  => Sizes'Size / System.Storage_Unit, 
         Value       => Sizes'Address, 
         Return_Size => null);
      Helpers.Error_Handler (Error);

      declare
         Result   : Binary_List (Sizes'Range);
         Pointers : aliased Address_List (Sizes'Range);
      begin
         for Index in Sizes'Range loop
            Result (Index) :=
              new SSE.Storage_Array
                (1 .. SSE.Storage_Offset (Sizes (Index)));
            if Sizes (Index) = 0 then
               Pointers (Index) := System.Null_Address;
            else
               Pointers (Index) := Result (Index) (Result (Index)'First)'Address;
            end if;
         end loop;

         Error := API.Get_Program_Info
           (Source      => Source.Location, 
            Param       => Enumerations.Binaries,
            Value_Size  => Pointers'Size / System.Storage_Unit, 
            Value       => Pointers'Address, 
            Return_Size => null);
         Helpers.Error_Handler (Error);
         return Result;
      end;
   end Binaries;

   function Status (Source : Program;
                    Device : Platforms.Device) return Build_Status is
      function Getter is
        new Helpers.Get_Parameter2 (Return_T    => Build_Status,
                                    Parameter_T => Enumerations.Program_Build_Info,
                                    C_Getter    => API.Get_Program_Build_Info);
   begin
      return Getter (Source, Device, Enumerations.Status);
   end Status;

   function Build_Options (Source : Program;
                           Device : Platforms.Device) return String is
   begin
      return String_Build_Info (Source, Device, Enumerations.Options);
   end Build_Options;

   function Build_Log (Source : Program;
                       Device : Platforms.Device) return String is
   begin
      return String_Build_Info (Source, Device, Enumerations.Log);
   end Build_Log;

   function Binary_Type
     (Source : Program; Device : Platforms.Device)
      return Program_Binary_Type
   is
      function Getter is
        new Helpers.Get_Parameter2
          (Return_T    => Program_Binary_Type,
           Parameter_T => Enumerations.Program_Build_Info,
           C_Getter    => API.Get_Program_Build_Info);
   begin
      return Getter (Source, Device, Enumerations.Binary_Type);
   end Binary_Type;

   procedure Unload_Platform_Compiler (Platform : Platforms.Platform) is
   begin
      Helpers.Error_Handler
        (API.Unload_Platform_Compiler (CL_Object (Platform).Location));
   end Unload_Platform_Compiler;

end CL.Programs;
