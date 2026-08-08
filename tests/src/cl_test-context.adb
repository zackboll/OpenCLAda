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

with AUnit.Assertions;

with CL.Platforms;
with CL.Contexts;
with CL_Test.Helpers;

with Ada.Text_IO;
with Ada.Strings.Fixed;

procedure CL_Test.Context is
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

   use Ada.Strings.Fixed;
   use type CL.Contexts.Context;
   use type CL.Platforms.Device;
   use type CL.Platforms.Platform;
   use type CL.UInt;

begin
   AUnit.Assertions.Assert
     (Dvs'Length > 0, "The selected OpenCL platform has no devices");

   ATI.Put_Line ("Device count is" & Dvs'Length'Img);

   --  create a context for the first device
   declare
      Context : constant CL.Contexts.Context
        := CL.Contexts.Constructors.Create_For_Devices
          (Pf, Dvs (1 .. 1), CL_Test.Helpers.Callback'Access);
   begin
      ATI.Put (Item => "Created context, reference count is");
      ATI.Put_Line (Context.Reference_Count'Img);
      AUnit.Assertions.Assert
        (Context.Initialized, "The device-list context was not initialized");
      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "A newly created context should have reference count 1");
      AUnit.Assertions.Assert
        (Context.Platform = Pf,
         "The context did not retain the requested platform");

      declare
         pragma Warnings (Off);
         Context2 : constant CL.Contexts.Context := Context;
         pragma Warnings (On);
      begin
         ATI.Put (Item => "Duplicated context, reference count is");
         ATI.Put_Line (Context.Reference_Count'Img);
         AUnit.Assertions.Assert
           (Context2 = Context, "The copied context refers to another object");
         AUnit.Assertions.Assert
           (Context.Reference_Count = 2,
            "Copying a context should increment its reference count");
      end;

      ATI.Put (Item => "Duplicated terminated, reference count is");
      ATI.Put_Line (Context.Reference_Count'Img);
      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "Finalizing a context copy should decrement its reference count");

      declare
         Devices : constant CL.Platforms.Device_List := Context.Devices;
      begin
         ATI.Put (Item => "Number of Devices is");
         ATI.Put_Line (Devices'Length'Img);
         AUnit.Assertions.Assert
           (Devices'Length = 1,
            "The context should contain exactly the requested device");
         AUnit.Assertions.Assert
           (Devices (Devices'First) = Dvs (Dvs'First),
            "The context returned a different device than requested");

         for Index in Devices'Range loop
            ATI.Put (Item => "#" & Index'Img & ": ");
            ATI.Put_Line (Devices (Index).Name);
         end loop;
      end;
   end;

   ATI.Put_Line (Item => 80 * '-');

   --  create a context for all GPU devices
   declare
      GPU_Devices    : constant CL.Platforms.Device_Kind :=
        CL.Platforms.Device_Kind'(GPU      => True,
                                  Reserved => [others => False],
                                  others   => False);
      Context        : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_From_Type
          (Pf, GPU_Devices,
           CL_Test.Helpers.Callback'Access);

      Returned_Pf : constant CL.Platforms.Platform := Context.Platform;
      Devices     : constant CL.Platforms.Device_List := Context.Devices;
   begin
      ATI.Put (Item => "Created context, reference count is");
      ATI.Put_Line (Context.Reference_Count'Img);
      AUnit.Assertions.Assert
        (Context.Initialized, "The GPU context was not initialized");
      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "A newly created GPU context should have reference count 1");
      AUnit.Assertions.Assert
        (Returned_Pf = Pf,
         "The GPU context did not retain the requested platform");
      AUnit.Assertions.Assert
        (Devices'Length > 0, "The GPU context contains no devices");

      for Device of Devices loop
         AUnit.Assertions.Assert
           (Device.Kind.GPU, "The GPU context contains a non-GPU device");
      end loop;
   end;
end CL_Test.Context;
