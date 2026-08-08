-------------------------------------------------------------------------------
--  Copyright (c) 2013, Felix Krause <contact@flyx.org>
--
--  Permission to use, copy, modify, and/or distribute this software for any
--  purpose with or without fee is hereby granted, provided that the above
--  copyright notice and this permission notice appear in all copies.
--
--  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
--  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
--  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
--  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
--  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
--  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
--  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
-------------------------------------------------------------------------------

with Ada.Strings.Fixed;
with Ada.Text_IO;

with AUnit.Assertions;

with CL.Contexts;
with CL.Memory;
with CL.Memory.Buffers;
with CL.Memory.Images;
with CL.Platforms;

with CL_Test.Helpers;

procedure CL_Test.Memory is
   package ATI renames Ada.Text_IO;

   Pfs : constant CL.Platforms.Platform_List := CL.Platforms.List;

   function First_Platform return CL.Platforms.Platform is
   begin
      AUnit.Assertions.Assert
        (Pfs'Length > 0, "No OpenCL platform was found");
      return Pfs (Pfs'First);
   end First_Platform;

   Pf  : constant CL.Platforms.Platform := First_Platform;
   Dvs : constant CL.Platforms.Device_List :=
     Pf.Devices (CL.Platforms.Device_Kind_All);

   function Create_Context return CL.Contexts.Context is
   begin
      AUnit.Assertions.Assert
        (Dvs'Length > 0, "The selected OpenCL platform has no devices");
      return CL.Contexts.Constructors.Create_For_Devices
        (Pf, Dvs, CL_Test.Helpers.Callback'Access);
   end Create_Context;

   Context : constant CL.Contexts.Context := Create_Context;

   use type CL.Contexts.Context;
   use type CL.Memory.Access_Kind;
   use type CL.Memory.Images.Image_Format;
   use type CL.Size;
   use type CL.UInt;
begin
   for Index in CL.Memory.Access_Kind loop
      ATI.Put_Line ("Context Refcount:" & Context.Reference_Count'Img);
      ATI.New_Line;
      ATI.Put_Line (Item => "Testing Buffer");
      declare
         Buffer : constant CL.Memory.Buffers.Buffer :=
           CL.Memory.Buffers.Constructors.Create (Context, Index, 1024);
      begin
         ATI.Put_Line (Item => "Created Buffer.");
         ATI.Put_Line ("Context Refcount:" & Context.Reference_Count'Img);
         AUnit.Assertions.Assert
           (Buffer.Mode = Index, "The buffer returned the wrong access mode");
         AUnit.Assertions.Assert
           (Buffer.Size = 1024, "The buffer returned the wrong size");
         ATI.Put_Line ("Map count:" & Buffer.Map_Count'Img);
         AUnit.Assertions.Assert
           (Buffer.Context = Context,
            "The buffer returned a different context");
         AUnit.Assertions.Assert
           (Buffer.Map_Count = 0,
            "A newly created buffer should not be mapped");
         ATI.Put_Line (Item => "Test completed.");
         ATI.Put_Line (Item => Ada.Strings.Fixed."*" (80, '-'));
      end;

      ATI.Put_Line ("Context Refcount:" & Context.Reference_Count'Img);
      ATI.Put_Line (Item => "Testing Image2D");
      --  Test 2D image
      declare
         --  Decide on an image format to use
         Format_List : constant CL.Memory.Images.Image_Format_List :=
           CL.Memory.Images.Supported_Image_Formats
             (Context, Index, CL.Memory.Images.T_Image2D);

         function First_Format return CL.Memory.Images.Image_Format is
         begin
            AUnit.Assertions.Assert
              (Format_List'Length > 0,
               "No 2D image format supports access mode " & Index'Image);
            return Format_List (Format_List'First);
         end First_Format;

         Format : constant CL.Memory.Images.Image_Format := First_Format;
         Image  : constant CL.Memory.Images.Image2D :=
           CL.Memory.Images.Constructors.Create_Image2D
             (Context, Index, Format, 1024, 512, 0);
      begin
         ATI.Put_Line (Item => "Created Image.");
         ATI.Put_Line ("Context Refcount:" & Context.Reference_Count'Img);
         ATI.Put_Line ("Size:" & Image.Size'Img);
         AUnit.Assertions.Assert
           (Image.Mode = Index, "The image returned the wrong access mode");
         AUnit.Assertions.Assert
           (Image.Context = Context,
            "The image returned a different context");
         AUnit.Assertions.Assert
           (Image.Format = Format, "The image returned the wrong format");
         AUnit.Assertions.Assert
           (Image.Width = 1024, "The image returned the wrong width");
         AUnit.Assertions.Assert
           (Image.Height = 512, "The image returned the wrong height");
         AUnit.Assertions.Assert
           (Image.Size > 0, "The image returned a zero allocation size");
         ATI.Put_Line ("Element size:" & Image.Element_Size'Img);
         AUnit.Assertions.Assert
           (Image.Element_Size > 0, "The image returned a zero element size");
         ATI.Put_Line ("Row pitch:" & Image.Row_Pitch'Img);
         AUnit.Assertions.Assert
           (Image.Row_Pitch > 0, "The image returned a zero row pitch");
         ATI.Put_Line (Item => "Test completed.");
         ATI.Put_Line (Item => Ada.Strings.Fixed."*" (80, '-'));
      end;
   end loop;
end CL_Test.Memory;