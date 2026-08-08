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

with CL.Platforms;
with CL.Contexts;
with CL.Programs;

package CL.Kernels is
   
   type Kernel is new Runtime_Object with null record;

   type Kernel_List is array (Positive range <>) of Kernel;

   type Argument_Address_Qualifier is
     (Global_Address, Local_Address, Constant_Address, Private_Address);
   type Argument_Access_Qualifier is
     (Read_Only_Access, Write_Only_Access, Read_Write_Access, No_Access);

   type Argument_Type_Qualifier_Reserved is mod 2 ** 61;

   type Argument_Type_Qualifier is record
      Is_Constant : Boolean := False;
      Is_Restrict : Boolean := False;
      Is_Volatile : Boolean := False;
      Reserved    : Argument_Type_Qualifier_Reserved := 0;
   end record;

   package Constructors is

      function Create (Source : Programs.Program'Class; Name : String) return Kernel;

      function Create_All_In_Program (Source : Programs.Program'Class)
                                      return Kernel_List;
   end Constructors;

   overriding procedure Adjust (Object : in out Kernel);

   overriding procedure Finalize (Object : in out Kernel);

   --  Only use the types declared in CL for Argument_Type.
   --  Do not use with CL tagged types; use Set_Kernel_Argument_Object instead
   generic
      type Argument_Type is private;
      Argument_Index : UInt;
   procedure Set_Kernel_Argument (Target : Kernel; Value : Argument_Type);

   procedure Set_Kernel_Argument_Object (Target : Kernel;
                                         Index  : UInt;
                                         Value : Runtime_Object'Class);

   function Function_Name (Source : Kernel) return String;

   function Argument_Number (Source : Kernel) return UInt;

   function Reference_Count (Source : Kernel) return UInt;

   function Context (Source : Kernel) return Contexts.Context;

   function Program (Source : Kernel) return Programs.Program;
   function Attributes (Source : Kernel) return String;

   function Argument_Address
     (Source : Kernel; Index : UInt) return Argument_Address_Qualifier;
   function Argument_Access
     (Source : Kernel; Index : UInt) return Argument_Access_Qualifier;
   function Argument_Type_Name
     (Source : Kernel; Index : UInt) return String;
   function Argument_Name
     (Source : Kernel; Index : UInt) return String;
   function Argument_Type_Qualifiers
     (Source : Kernel; Index : UInt) return Argument_Type_Qualifier;

   function Work_Group_Size (Source : Kernel; Device : Platforms.Device)
                             return Size;

   function Compile_Work_Group_Size (Source : Kernel; Device : Platforms.Device)
                                     return Size_List;

   function Local_Memory_Size (Source : Kernel; Device : Platforms.Device)
                               return ULong;
   function Preferred_Work_Group_Size_Multiple
     (Source : Kernel; Device : Platforms.Device) return Size;
   function Private_Memory_Size
     (Source : Kernel; Device : Platforms.Device) return ULong;
   function Global_Work_Size
     (Source : Kernel; Device : Platforms.Device) return Size_List;

private
   for Argument_Address_Qualifier use
     (Global_Address   => 16#119B#,
      Local_Address    => 16#119C#,
      Constant_Address => 16#119D#,
      Private_Address  => 16#119E#);
   for Argument_Address_Qualifier'Size use UInt'Size;

   for Argument_Access_Qualifier use
     (Read_Only_Access  => 16#11A0#,
      Write_Only_Access => 16#11A1#,
      Read_Write_Access => 16#11A2#,
      No_Access         => 16#11A3#);
   for Argument_Access_Qualifier'Size use UInt'Size;

   for Argument_Type_Qualifier use record
      Is_Constant at 0 range 0 .. 0;
      Is_Restrict at 0 range 1 .. 1;
      Is_Volatile at 0 range 2 .. 2;
      Reserved    at 0 range 3 .. 63;
   end record;
   for Argument_Type_Qualifier'Size use Bitfield'Size;
   pragma Convention (C_Pass_By_Copy, Argument_Type_Qualifier);
end CL.Kernels;
