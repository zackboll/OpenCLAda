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

with Ada.Text_IO;

with AUnit.Assertions;

with CL.Platforms;

procedure CL_Test.Platform is
   package IO renames Ada.Text_IO;

   P_List : constant CL.Platforms.Platform_List := CL.Platforms.List;
begin
   AUnit.Assertions.Assert
     (P_List'Length > 0, "No OpenCL platform was found");

   for Index in P_List'Range loop
      declare
         Profile : constant String := P_List (Index).Profile;
         Version : constant String := P_List (Index).Version;
         Name    : constant String := P_List (Index).Name;
         Vendor  : constant String := P_List (Index).Vendor;
      begin
         IO.Put_Line (Item => "Platform" & Index'Img);
         IO.Put_Line (Item => "Profile: """ & Profile & """");
         IO.Put_Line (Item => "Version: """ & Version & """");
         IO.Put_Line (Item => "Name: """ & Name & """");
         IO.Put_Line (Item => "Vendor: """ & Vendor & """");
         IO.Put_Line
           ("Extensions: """ & P_List (Index).Extensions & """");

         AUnit.Assertions.Assert
           (Profile = "FULL_PROFILE" or else Profile = "EMBEDDED_PROFILE",
            "Platform" & Index'Image & " returned an invalid profile");
         AUnit.Assertions.Assert
           (Version'Length > 0,
            "Platform" & Index'Image & " returned an empty version");
         AUnit.Assertions.Assert
           (Name'Length > 0,
            "Platform" & Index'Image & " returned an empty name");
         AUnit.Assertions.Assert
           (Vendor'Length > 0,
            "Platform" & Index'Image & " returned an empty vendor");
      end;
      IO.Put_Line (Item => "");
   end loop;
end CL_Test.Platform;