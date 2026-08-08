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

package body CL.Memory.Buffers is

   use type System.Address;

   package body Constructors is

      function Create (Context         : Contexts.Context'Class;
                       Mode            : Access_Kind;
                       Size            : CL.Size;
                       Use_Host_Memory : Boolean := False) return Buffer is
         Flags      : Memory_Flags;
         Raw_Object : System.Address;
         Error      : aliased Enumerations.Error_Code;
      begin
         Flags := Create_Flags (Mode => Mode, Alloc_Host_Ptr => Use_Host_Memory);
         Raw_Object := API.Create_Buffer 
           (Context  => CL_Object (Context).Location,
            Flags    => To_Bitfield (Flags),
            Size     => Size, 
            Host_Ptr => System.Null_Address,
            Error    => Error'Unchecked_Access);
         Helpers.Error_Handler (Error);
         return Buffer'(Ada.Finalization.Controlled with Location => Raw_Object);
      end Create;

      function Create_From_Source (Context              : Contexts.Context'Class;
                                   Mode                 : Access_Kind;
                                   Source               : Element_List;
                                   Use_Source_As_Buffer : Boolean := False;
                                   Use_Host_Memory      : Boolean := False)
                                   return Buffer is
         Flags      : Memory_Flags;
         Raw_Object : System.Address;
         Error      : aliased Enumerations.Error_Code;
       begin
          if Source'Length = 0 then
             raise Invalid_Buffer_Size;
          end if;

          if Use_Source_As_Buffer then
            if not Use_Host_Memory then
               raise Invalid_Value with "Use_Source_As_Buffer requires Use_Host_Memory.";
            end if;
            Flags := Create_Flags (Mode           => Mode,
                                   Use_Host_Ptr   => True,
                                   Copy_Host_Ptr  => False,
                                   Alloc_Host_Ptr => False);
         else
            Flags := Create_Flags (Mode           => Mode,
                                   Use_Host_Ptr   => False,
                                   Copy_Host_Ptr  => True,
                                   Alloc_Host_Ptr => Use_Host_Memory);
         end if;

         Raw_Object
           := API.Create_Buffer (Context  => CL_Object (Context).Location,
                                 Flags    => To_Bitfield (Flags),
                                 Size     => Source'Size / System.Storage_Unit,
                                 Host_Ptr => Source (Source'First)'Address,
                                 Error    => Error'Unchecked_Access);
          Helpers.Error_Handler (Error);
          return Buffer'(Ada.Finalization.Controlled with Location => Raw_Object);
      end Create_From_Source;

   end Constructors;

   function Create_Sub_Buffer_Region
     (Source      : Buffer;
      Mode        : Access_Kind;
      Region      : Buffer_Region;
      Host_Access : Host_Access_Kind := Host_Read_Write) return Buffer
   is
      Flags      : constant Memory_Flags :=
        Create_Flags (Mode => Mode, Host_Access => Host_Access);
      Region_Obj : aliased Buffer_Region := Region;
      Error      : aliased Enumerations.Error_Code;
      Raw_Object : System.Address;
   begin
      Raw_Object := API.Create_Sub_Buffer
        (Source      => Source.Location, 
         Flags       => To_Bitfield (Flags), 
         Create_Type => Enumerations.T_Region,
         Info        => Region_Obj'Address, 
         Error       => Error'Unchecked_Access);
      Helpers.Error_Handler (Error);
      return Buffer'(Ada.Finalization.Controlled with Location => Raw_Object);
   end Create_Sub_Buffer_Region;

   function Associated_Object (Source : Buffer) return Buffer is
      Raw_Object : constant System.Address := Associated_Object_Raw (Source);
   begin
      if Raw_Object = System.Null_Address then
         return Buffer'(Ada.Finalization.Controlled with
                        Location => System.Null_Address);
      end if;

      Helpers.Error_Handler (API.Retain_Mem_Object (Raw_Object));
      return Buffer'(Ada.Finalization.Controlled with Location => Raw_Object);
   end Associated_Object;
end CL.Memory.Buffers;
