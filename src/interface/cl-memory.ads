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

with CL.Contexts;

private with Ada.Unchecked_Conversion;

package CL.Memory is
   type Memory_Object is abstract new Runtime_Object with null record;

   type Access_Kind is (Read_Only, Write_Only, Read_Write);
   type Host_Access_Kind is
     (Host_Read_Write, Host_Write_Only, Host_Read_Only, Host_No_Access);

   type Memory_Object_Kind is
     (Buffer_Object, Image2D_Object, Image3D_Object, Image2D_Array_Object,
      Image1D_Object, Image1D_Array_Object, Image1D_Buffer_Object);

   overriding procedure Adjust (Object : in out Memory_Object);
   overriding procedure Finalize (Object : in out Memory_Object);

   function Mode (Source : Memory_Object) return Access_Kind;

   function In_Host_Memory (Source : Memory_Object) return Boolean;

   function Size (Source : Memory_Object) return CL.Size;

   function Map_Count (Source : Memory_Object) return UInt;

   function Reference_Count (Source : Memory_Object) return UInt;

   function Context (Source : Memory_Object) return Contexts.Context;
   function Kind (Source : Memory_Object) return Memory_Object_Kind;
   function Host_Pointer (Source : Memory_Object) return System.Address;
   function Associated_Object_Raw
     (Source : Memory_Object) return System.Address;
   function Offset (Source : Memory_Object) return CL.Size;

   type Destructor_Callback is
     access procedure (Destroyed_Object : System.Address);
   procedure Set_Destructor_Callback
     (Target : Memory_Object'Class; Callback : Destructor_Callback);

private
   type Bits54 is mod 2 ** 54;
   type Memory_Flags is
      record
         Read_Write     : Boolean := False;
         Write_Only     : Boolean := False;
         Read_Only      : Boolean := False;
         Use_Host_Ptr   : Boolean := False;
         Alloc_Host_Ptr : Boolean := False;
         Copy_Host_Ptr  : Boolean := False;
         Reserved_6     : Boolean := False;
         Host_Write_Only : Boolean := False;
         Host_Read_Only  : Boolean := False;
         Host_No_Access  : Boolean := False;
         Reserved        : Bits54  := 0;
      end record;

   for Memory_Flags use
      record
         Read_Write     at 0 range 0 .. 0;
         Write_Only     at 0 range 1 .. 1;
         Read_Only      at 0 range 2 .. 2;
         Use_Host_Ptr   at 0 range 3 .. 3;
         Alloc_Host_Ptr at 0 range 4 .. 4;
         Copy_Host_Ptr   at 0 range 5 .. 5;
         Reserved_6      at 0 range 6 .. 6;
         Host_Write_Only at 0 range 7 .. 7;
         Host_Read_Only  at 0 range 8 .. 8;
         Host_No_Access  at 0 range 9 .. 9;
         Reserved        at 0 range 10 .. 63;
      end record;
   for Memory_Flags'Size use Bitfield'Size;
   pragma Convention (C_Pass_By_Copy, Memory_Flags);

   function Flags (Source : Memory_Object) return Memory_Flags;

   function Create_Flags
     (Mode : Access_Kind;
      Use_Host_Ptr, Copy_Host_Ptr, Alloc_Host_Ptr : Boolean := False;
      Host_Access : Host_Access_Kind := Host_Read_Write)
      return Memory_Flags;

   function To_Bitfield is new
     Ada.Unchecked_Conversion (Source => Memory_Flags,
                               Target => Bitfield);

   for Memory_Object_Kind use
     (Buffer_Object         => 16#10F0#,
      Image2D_Object        => 16#10F1#,
      Image3D_Object        => 16#10F2#,
      Image2D_Array_Object  => 16#10F3#,
      Image1D_Object        => 16#10F4#,
      Image1D_Array_Object  => 16#10F5#,
      Image1D_Buffer_Object => 16#10F6#);
   for Memory_Object_Kind'Size use UInt'Size;
end CL.Memory;
