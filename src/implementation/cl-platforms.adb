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

with Ada.Unchecked_Conversion;
with Interfaces.C.Strings;
with System;

with CL.API;
with CL.Helpers;
with CL.Enumerations;

package body CL.Platforms is

   use type System.Address;

   Partition_Equally_Kind            : constant Partition_Property := 16#1086#;
   Partition_By_Counts_Kind          : constant Partition_Property := 16#1087#;
   Partition_By_Affinity_Domain_Kind : constant Partition_Property := 16#1088#;

   function Affinity_Value (Domain : Affinity_Domain)
                            return Partition_Property is
     (Partition_Property (2 ** Affinity_Domain'Pos (Domain)));

   -----------------------------------------------------------------------------
   --  Helper instantiations
   -----------------------------------------------------------------------------

   function Platform_String_Info is
     new Helpers.Get_String (Parameter_T => Enumerations.Platform_Info,
                             C_Getter    => API.Get_Platform_Info);

   function UInt_Info is
     new Helpers.Get_Parameter (Return_T    => CL.UInt,
                                Parameter_T => Enumerations.Device_Info,
                                C_Getter    => API.Get_Device_Info);

   function ULong_Info is
     new Helpers.Get_Parameter (Return_T    => CL.ULong,
                                Parameter_T => Enumerations.Device_Info,
                                C_Getter    => API.Get_Device_Info);

   function Size_Info is
     new Helpers.Get_Parameter (Return_T    => Size,
                                Parameter_T => Enumerations.Device_Info,
                                C_Getter    => API.Get_Device_Info);

   function Bool_Info is
     new Helpers.Get_Parameter (Return_T    => CL.Bool,
                                Parameter_T => Enumerations.Device_Info,
                                C_Getter    => API.Get_Device_Info);

   function String_Info is
     new Helpers.Get_String (Parameter_T => Enumerations.Device_Info,
                             C_Getter    => API.Get_Device_Info);

   -----------------------------------------------------------------------------
   --  Implementations
   -----------------------------------------------------------------------------

   function Create_Sub_Devices
     (Source : Device; Properties : Partition_Property_List)
      return Device_List
   is
      Count : aliased UInt := 0;
      Error : Enumerations.Error_Code;
   begin
      Error := API.Create_Sub_Devices
        (Device          => Source.Location, 
         Properties      => Properties (Properties'First)'Address, 
         Num_Devices     => 0,
         Devices         => System.Null_Address, 
         Num_Devices_Ret => Count'Unchecked_Access);
      Helpers.Error_Handler (Error);

      declare
         Raw_Devices : Address_List (1 .. Integer (Count));
         Result      : Device_List (1 .. Integer (Count));
      begin
         Error := API.Create_Sub_Devices
           (Device          => Source.Location, 
            Properties      => Properties (Properties'First)'Address, 
            Num_Devices     => Count,
            Devices         => Raw_Devices (Raw_Devices'First)'Address, 
            Num_Devices_Ret => null);
         Helpers.Error_Handler (Error);

         for Index in Result'Range loop
            Result (Index) :=
              Device'(Ada.Finalization.Controlled with
                      Location       => Raw_Devices (Index),
                      Owns_Reference => True);
         end loop;
         return Result;
      end;
   end Create_Sub_Devices;

   package body Raw_Interop is
      function Wrap_Device
        (Location : System.Address; Retain : Boolean := False) return Device
      is
         Result : constant Device :=
           Device'(Ada.Finalization.Controlled with
                   Location       => Location,
                   Owns_Reference => Retain and Location /= System.Null_Address);
         Error : Enumerations.Error_Code;
      begin
         if Result.Owns_Reference then
            Error := API.Retain_Device (Location);
            Helpers.Error_Handler (Error);
         end if;
         return Result;
      end Wrap_Device;
   end Raw_Interop;

   package body Device_Constructors is
      function Partition_Equally
        (Source : Device; Compute_Units_Per_Sub_Device : UInt)
         return Device_List
      is
         Properties : aliased constant Partition_Property_List :=
           [Partition_Equally_Kind,
            Partition_Property (Compute_Units_Per_Sub_Device), 0];
      begin
         return Create_Sub_Devices (Source     => Source, 
                                    Properties => Properties);
      end Partition_Equally;

      function Partition_By_Counts
        (Source : Device; Compute_Unit_Counts : Size_List)
         return Device_List
      is
         Properties : aliased Partition_Property_List
           (1 .. Compute_Unit_Counts'Length + 3);
      begin
         Properties (1) := Partition_By_Counts_Kind;
         for Index in Compute_Unit_Counts'Range loop
            Properties (Index - Compute_Unit_Counts'First + 2) :=
              Partition_Property (Compute_Unit_Counts (Index));
         end loop;
         Properties (Properties'Last - 1) := 0;
         Properties (Properties'Last) := 0;
         return Create_Sub_Devices (Source     => Source, 
                                    Properties => Properties);
      end Partition_By_Counts;

      function Partition_By_Affinity_Domain
        (Source : Device; 
         Domain : Affinity_Domain)
         return Device_List
      is
         Properties : aliased constant Partition_Property_List :=
           [Partition_By_Affinity_Domain_Kind, Affinity_Value (Domain), 0];
      begin
         return Create_Sub_Devices (Source     => Source, 
                                    Properties => Properties);
      end Partition_By_Affinity_Domain;
   end Device_Constructors;

   function List return Platform_List is
      Platform_Count   : aliased UInt;
      Error            : Enumerations.Error_Code;
   begin
      Error := API.Get_Platform_IDs 
        (Num_Entries => 0, 
         Value => System.Null_Address,
         Num_Platforms => Platform_Count'Unchecked_Access);
      Helpers.Error_Handler (Error);
      declare
         Raw_List    : Address_List  (1 .. Integer (Platform_Count));
         Return_List : Platform_List (1 .. Integer (Platform_Count));
      begin
         Error := API.Get_Platform_IDs 
           (Num_Entries   => Platform_Count,
            Value         => Raw_List (1)'Address, 
            Num_Platforms => null);
         Helpers.Error_Handler (Error);
         for Index in Raw_List'Range loop
            Return_List (Index) := Platform'(Ada.Finalization.Controlled with
                                             Location => Raw_List (Index));
         end loop;
         return Return_List;
      end;
   end List;

   function Profile (Source : Platform) return String is
   begin
      return Platform_String_Info (Source, Enumerations.Profile);
   end Profile;

   function Version (Source : Platform) return String is
   begin
      return Platform_String_Info (Source, Enumerations.Version);
   end Version;

   function Name (Source : Platform) return String is
   begin
      return Platform_String_Info (Source, Enumerations.Name);
   end Name;

   function Vendor (Source : Platform) return String is
   begin
      return Platform_String_Info (Source, Enumerations.Vendor);
   end Vendor;

   function Extensions (Source : Platform) return String is
   begin
      return Platform_String_Info (Source, Enumerations.Extensions);
   end Extensions;

   function Extension_Function_Address
     (Source : Platform; Function_Name : String) return System.Address
   is
      C_Name : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Function_Name);
      Result : System.Address;
   begin
      Result := API.Get_Extension_Function_Address_For_Platform
        (Platform => Source.Location, 
         Name     => C_Name);
      Interfaces.C.Strings.Free (C_Name);
      return Result;
   end Extension_Function_Address;

   function Devices (Source : Platform; Types : Device_Kind)
                     return Device_List is
      Device_Count : aliased UInt;
      Error        : Enumerations.Error_Code;

      function To_Bitfield is
        new Ada.Unchecked_Conversion (Source => Device_Kind, 
                                      Target => Bitfield);
   begin
      Error := API.Get_Device_IDs (Source      => Source.Location, 
                                   Types       => To_Bitfield (Types), 
                                   Num_Entries => 0,
                                   Value       => System.Null_Address,
                                   Num_Devices => Device_Count'Unchecked_Access);
      Helpers.Error_Handler (Error);
      declare
         Raw_List : Address_List (1 .. Integer (Device_Count));
         Return_List : Device_List (1 .. Integer (Device_Count));
      begin
         Error := API.Get_Device_IDs (Source      => Source.Location, 
                                      Types       => To_Bitfield (Types),
                                      Num_Entries => Device_Count,
                                      Value       => Raw_List (1)'Address, 
                                      Num_Devices => null);
         Helpers.Error_Handler (Error);

         for Index in Raw_List'Range loop
             Return_List (Index) :=
               Device'(Ada.Finalization.Controlled with
                       Location       => Raw_List (Index),
                       Owns_Reference => False);
         end loop;
         return Return_List;
      end;
   end Devices;

   function Vendor_ID (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Vendor_ID);
   end Vendor_ID;

   function Max_Compute_Units (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Compute_Units);
   end Max_Compute_Units;

   function Max_Work_Item_Dimensions (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Work_Item_Dimensions);
   end Max_Work_Item_Dimensions;

   function Preferred_Vector_Width_Char (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Char);
   end Preferred_Vector_Width_Char;

   function Preferred_Vector_Width_Short (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Short);
   end Preferred_Vector_Width_Short;

   function Preferred_Vector_Width_Int (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Int);
   end Preferred_Vector_Width_Int;

   function Preferred_Vector_Width_Long (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Long);
   end Preferred_Vector_Width_Long;

   function Preferred_Vector_Width_Float (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Float);
   end Preferred_Vector_Width_Float;

   function Preferred_Vector_Width_Double (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Double);
   end Preferred_Vector_Width_Double;

   function Max_Clock_Frequency (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Clock_Frequency);
   end Max_Clock_Frequency;

   function Address_Bits (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Address_Bits);
   end Address_Bits;

   function Max_Read_Image_Args (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Read_Image_Args);
   end Max_Read_Image_Args;

   function Max_Write_Image_Args (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Write_Image_Args);
   end Max_Write_Image_Args;

   function Max_Samplers (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Samplers);
   end Max_Samplers;

   function Mem_Base_Addr_Align (Source: Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Mem_Base_Addr_Align);
   end Mem_Base_Addr_Align;

   function Min_Data_Type_Align_Size (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Min_Data_Type_Align_Size);
   end Min_Data_Type_Align_Size;

   function Global_Mem_Cacheline_Size (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Global_Mem_Cacheline_Size);
   end Global_Mem_Cacheline_Size;

   function Max_Constant_Args (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Max_Constant_Args);
   end Max_Constant_Args;

   function Preferred_Vector_Width_Half (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Preferred_Vector_Width_Half);
   end Preferred_Vector_Width_Half;

   function Native_Vector_Width_Char (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Char);
   end Native_Vector_Width_Char;

   function Native_Vector_Width_Short (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Short);
   end Native_Vector_Width_Short;

   function Native_Vector_Width_Int (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Int);
   end Native_Vector_Width_Int;

   function Native_Vector_Width_Long (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Long);
   end Native_Vector_Width_Long;

   function Native_Vector_Width_Float (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Float);
   end Native_Vector_Width_Float;

   function Native_Vector_Width_Double (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Double);
   end Native_Vector_Width_Double;

   function Native_Vector_Width_Half (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Native_Vector_Width_Half);
   end Native_Vector_Width_Half;

   function Partition_Max_Sub_Devices (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Partition_Max_Sub_Devices);
   end Partition_Max_Sub_Devices;

   function Device_Reference_Count (Source : Device) return UInt is
   begin
      return UInt_Info (Source, Enumerations.Device_Reference_Count);
   end Device_Reference_Count;

   function Max_Mem_Alloc_Size (Source : Device) return ULong is
   begin
      return ULong_Info (Source, Enumerations.Max_Mem_Alloc_Size);
   end Max_Mem_Alloc_Size;

   function Global_Mem_Cache_Size (Source : Device) return ULong is
   begin
      return ULong_Info (Source, Enumerations.Global_Mem_Cache_Size);
   end Global_Mem_Cache_Size;

   function Global_Mem_Size (Source : Device) return ULong is
   begin
      return ULong_Info (Source, Enumerations.Global_Mem_Size);
   end Global_Mem_Size;

   function Max_Constant_Buffer_Size (Source : Device) return ULong is
   begin
      return ULong_Info (Source, Enumerations.Max_Constant_Buffer_Size);
   end Max_Constant_Buffer_Size;

   function Local_Mem_Size (Source : Device) return ULong is
   begin
      return ULong_Info (Source, Enumerations.Local_Mem_Size);
   end Local_Mem_Size;

   function Max_Work_Group_Size (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Max_Work_Group_Size);
   end Max_Work_Group_Size;

   function Image2D_Max_Width (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image2D_Max_Width);
   end Image2D_Max_Width;

   function Image2D_Max_Height (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image2D_Max_Height);
   end Image2D_Max_Height;

   function Image3D_Max_Width (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image3D_Max_Width);
   end Image3D_Max_Width;

   function Image3D_Max_Height (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image3D_Max_Height);
   end Image3D_Max_Height;

   function Image3D_Max_Depth (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image3D_Max_Depth);
   end Image3D_Max_Depth;

   function Max_Parameter_Size (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Max_Parameter_Size);
   end Max_Parameter_Size;

   function Profiling_Timer_Resolution (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Profiling_Timer_Resolution);
   end Profiling_Timer_Resolution;

   function Image_Max_Buffer_Size (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image_Max_Buffer_Size);
   end Image_Max_Buffer_Size;

   function Image_Max_Array_Size (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Image_Max_Array_Size);
   end Image_Max_Array_Size;

   function Printf_Buffer_Size (Source : Device) return Size is
   begin
      return Size_Info (Source, Enumerations.Printf_Buffer_Size);
   end Printf_Buffer_Size;

   function Image_Support (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Image_Support));
   end Image_Support;

   function Error_Correction_Support (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Error_Correction_Support));
   end Error_Correction_Support;

   function Endian_Little (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Endian_Little));
   end Endian_Little;

   function Available (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Available));
   end Available;

   function Compiler_Available (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Compiler_Available));
   end Compiler_Available;

   function Host_Unified_Memory (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Host_Unified_Memory));
   end Host_Unified_Memory;

   function Linker_Available (Source : Device) return Boolean is
   begin
      return Boolean (Bool_Info (Source, Enumerations.Linker_Available));
   end Linker_Available;

   function Preferred_Interop_User_Sync (Source : Device) return Boolean is
   begin
      return Boolean
        (Bool_Info (Source, Enumerations.Preferred_Interop_User_Sync));
   end Preferred_Interop_User_Sync;

   function Name (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Name);
   end Name;

   function Vendor (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Vendor);
   end Vendor;

   function Driver_Version (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Driver_Version);
   end Driver_Version;

   function Profile (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Profile);
   end Profile;

   function Version (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Version);
   end Version;

   function Extensions (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Extensions);
   end Extensions;

   function OpenCL_C_Version (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.OpenCL_C_Version);
   end OpenCL_C_Version;

   function Built_In_Kernels (Source : Device) return String is
   begin
      return String_Info (Source, Enumerations.Built_In_Kernels);
   end Built_In_Kernels;

   function Max_Work_Item_Sizes (Source : Device) return Size_List is
      function Getter is
        new Helpers.Get_Parameters (Return_Element_T => Size,
                                    Return_T         => Size_List,
                                    Parameter_T      => Enumerations.Device_Info,
                                    C_Getter         => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Max_Work_Item_Sizes);
   end Max_Work_Item_Sizes;

   function Decode_Floating_Point_Config is
     new Ada.Unchecked_Conversion
       (Source => Bitfield, Target => Floating_Point_Config);

   function Single_Floating_Point_Config (Source : Device)
                                          return Floating_Point_Config is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Bitfield,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Decode_Floating_Point_Config
        (Getter (Source, Enumerations.Single_FP_Config));
   end Single_Floating_Point_Config;

   function Double_Floating_Point_Config (Source : Device)
                                          return Floating_Point_Config is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Bitfield,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Decode_Floating_Point_Config
        (Getter (Source, Enumerations.Double_FP_Config));
   end Double_Floating_Point_Config;

   function Memory_Cache_Type (Source : Device) return Memory_Cache_Kind is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Memory_Cache_Kind,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Global_Mem_Cache_Type);
   end Memory_Cache_Type;

   function Local_Memory_Type (Source : Device) return Local_Memory_Kind is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Local_Memory_Kind,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Local_Mem_Type);
   end Local_Memory_Type;

   function Kind (Source : Device) return Device_Kind is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Device_Kind,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Dev_Type);
   end Kind;

   function Execution_Capabilities (Source : Device)
                                    return Capability_Vector is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Bitfield,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
      Raw : constant Bitfield :=
        Getter (Source, Enumerations.Execution_Capabilities);
   begin
      return (Kernel        => (Raw and 1) /= 0,
              Native_Kernel => (Raw and 2) /= 0);
   end Execution_Capabilities;

   function Command_Queue_Properties (Source : Device)
                                      return CQ_Property_Vector is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => CQ_Property_Vector,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Queue_Properties);
   end Command_Queue_Properties;

   function Associated_Platform (Source : Device) return Platform'Class is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
   begin
      return Platform'(Ada.Finalization.Controlled with
                       Location => Getter (Source, Enumerations.Platform));
   end Associated_Platform;

   function Parent (Source : Device) return Device is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Device_Info,
                                   C_Getter    => API.Get_Device_Info);
      Location : constant System.Address :=
        Getter (Source, Enumerations.Parent_Device);
   begin
      return Raw_Interop.Wrap_Device (Location => Location, Retain => True);
   end Parent;

   function Partition_Properties
     (Source : Device) return Partition_Property_List
   is
      function Getter is
        new Helpers.Get_Parameters
          (Return_Element_T => Partition_Property,
           Return_T         => Partition_Property_List,
           Parameter_T      => Enumerations.Device_Info,
           C_Getter         => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Partition_Properties);
   end Partition_Properties;

   function Partition_Type
     (Source : Device) return Partition_Property_List
   is
      function Getter is
        new Helpers.Get_Parameters
          (Return_Element_T => Partition_Property,
           Return_T         => Partition_Property_List,
           Parameter_T      => Enumerations.Device_Info,
           C_Getter         => API.Get_Device_Info);
   begin
      return Getter (Source, Enumerations.Partition_Type);
   end Partition_Type;

   function Partition_Affinity_Domains
     (Source : Device) return Affinity_Domain_Set
   is
      function Getter is
        new Helpers.Get_Parameter
          (Return_T    => Bitfield,
           Parameter_T => Enumerations.Device_Info,
           C_Getter    => API.Get_Device_Info);
      Raw : constant Bitfield :=
        Getter (Source, Enumerations.Partition_Affinity_Domain);
      Result : Affinity_Domain_Set := [others => False];
   begin
      for Domain in Affinity_Domain loop
         Result (Domain) :=
           (Raw and Bitfield (Affinity_Value (Domain))) /= 0;
      end loop;
      return Result;
   end Partition_Affinity_Domains;

   overriding procedure Adjust (Object : in out Device) is
      Error : Enumerations.Error_Code;
   begin
      if Object.Owns_Reference and Object.Location /= System.Null_Address then
         Error := API.Retain_Device (Object.Location);
         Helpers.Error_Handler (Error);
      end if;
   end Adjust;

   overriding procedure Finalize (Object : in out Device) is
      Error : Enumerations.Error_Code;
   begin
      if Object.Owns_Reference and Object.Location /= System.Null_Address then
         Error := API.Release_Device (Device => Object.Location);
         Helpers.Error_Handler (Error);
         Object.Location := System.Null_Address;
      end if;
   end Finalize;
end CL.Platforms;
