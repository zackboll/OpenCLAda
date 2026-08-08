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

with CL.API;
with CL.Enumerations;
with CL.Helpers;

package body CL.Memory is


   -----------------------------------------------------------------------------
   --  Helpers
   -----------------------------------------------------------------------------

   function UInt_Info is
     new Helpers.Get_Parameter (Return_T    => UInt,
                                Parameter_T => Enumerations.Memory_Info,
                                C_Getter    => API.Get_Mem_Object_Info);

   function Size_Info is
     new Helpers.Get_Parameter (Return_T    => CL.Size,
                                Parameter_T => Enumerations.Memory_Info,
                                C_Getter    => API.Get_Mem_Object_Info);

   function Type_Info is
     new Helpers.Get_Parameter (Return_T    => Memory_Object_Kind,
                                Parameter_T => Enumerations.Memory_Info,
                                C_Getter    => API.Get_Mem_Object_Info);

   function Address_Info is
     new Helpers.Get_Parameter (Return_T    => System.Address,
                                Parameter_T => Enumerations.Memory_Info,
                                C_Getter    => API.Get_Mem_Object_Info);

   function Callback_To_Address is
     new Ada.Unchecked_Conversion (Destructor_Callback, System.Address);
   function Address_To_Callback is
     new Ada.Unchecked_Conversion (System.Address, Destructor_Callback);

   procedure Destructor_Callback_Dispatcher
     (Object : System.Address; User_Data : System.Address);
   pragma Convention (C, Destructor_Callback_Dispatcher);

   procedure Destructor_Callback_Dispatcher
     (Object : System.Address; User_Data : System.Address)
   is
      Callback : constant Destructor_Callback :=
        Address_To_Callback (User_Data);
   begin
      if Callback /= null then
         Callback (Destroyed_Object => Object);
      end if;
   end Destructor_Callback_Dispatcher;

   -----------------------------------------------------------------------------
   --  Implementations
   -----------------------------------------------------------------------------

   overriding procedure Adjust (Object : in out Memory_Object) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Retain_Mem_Object (Object.Location));
      end if;
   end Adjust;

   overriding procedure Finalize (Object : in out Memory_Object) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Release_Mem_Object (Object.Location));
      end if;
   end Finalize;

   function Flags (Source : Memory_Object) return Memory_Flags is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Memory_Flags,
                                   Parameter_T => Enumerations.Memory_Info,
                                   C_Getter    => API.Get_Mem_Object_Info);
   begin
      return Getter (Source, Enumerations.Flags);
   end Flags;

   function Mode (Source : Memory_Object) return Access_Kind is
      Flags : constant Memory_Flags := Source.Flags;
   begin
      if Flags.Write_Only then
         return Write_Only;
      end if;
      if Flags.Read_Only then
         return Read_Only;
      end if;
      return Read_Write;
   end Mode;

   function In_Host_Memory (Source : Memory_Object) return Boolean is
      Flags : constant Memory_Flags := Source.Flags;
   begin
      return (Flags.Use_Host_Ptr or Flags.Alloc_Host_Ptr);
   end In_Host_Memory;

   function Size (Source : Memory_Object) return CL.Size is
   begin
      return Size_Info (Source, Enumerations.Size);
   end Size;

   function Map_Count (Source : Memory_Object) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Map_Count);
   end Map_Count;

   function Reference_Count (Source : Memory_Object) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Reference_Count);
   end Reference_Count;

   function Kind (Source : Memory_Object) return Memory_Object_Kind is
   begin
      return Type_Info (Source, Enumerations.Mem_Type);
   end Kind;

   function Host_Pointer (Source : Memory_Object) return System.Address is
   begin
      return Address_Info (Source, Enumerations.Host_Ptr);
   end Host_Pointer;

   function Associated_Object_Raw
     (Source : Memory_Object) return System.Address is
   begin
      return Address_Info (Source, Enumerations.Associated_Memobject);
   end Associated_Object_Raw;

   function Offset (Source : Memory_Object) return CL.Size is
   begin
      return Size_Info (Source, Enumerations.Offset);
   end Offset;

   function Context (Source : Memory_Object) return Contexts.Context is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Memory_Info,
                                   C_Getter    => API.Get_Mem_Object_Info);
      function New_Context_Reference is
         new Helpers.New_Reference (Object_T => Contexts.Context);
   begin
      return New_Context_Reference (Getter (Source, Enumerations.Context));
   end Context;

   procedure Set_Destructor_Callback
     (Target : Memory_Object'Class; Callback : Destructor_Callback) is
   begin
      if Callback = null then
         raise Constraint_Error with "destructor callback must not be null";
      end if;
      Helpers.Error_Handler
        (API.Set_Mem_Object_Destructor_Callback
           (Object    => Target.Location, 
            Callback  => Destructor_Callback_Dispatcher'Access,
            User_Data => Callback_To_Address (Callback)));
   end Set_Destructor_Callback;

   function Create_Flags
     (Mode : Access_Kind;
      Use_Host_Ptr, Copy_Host_Ptr, Alloc_Host_Ptr : Boolean := False;
      Host_Access : Host_Access_Kind := Host_Read_Write)
      return Memory_Flags is
      Flags : Memory_Flags;
   begin
      case Mode is
         when Read_Only  => Flags.Read_Only  := True;
         when Write_Only => Flags.Write_Only := True;
         when Read_Write => Flags.Read_Write := True;
      end case;
       Flags.Use_Host_Ptr   := Use_Host_Ptr;
       Flags.Copy_Host_Ptr  := Copy_Host_Ptr;
       Flags.Alloc_Host_Ptr := Alloc_Host_Ptr;
       case Host_Access is
          when Host_Read_Write => null;
          when Host_Write_Only => Flags.Host_Write_Only := True;
          when Host_Read_Only  => Flags.Host_Read_Only := True;
          when Host_No_Access  => Flags.Host_No_Access := True;
       end case;
       return Flags;
   end Create_Flags;

end CL.Memory;
