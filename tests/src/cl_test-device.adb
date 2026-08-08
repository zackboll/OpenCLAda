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

with CL.Platforms;

procedure CL_Test.Device is
   package IO renames Ada.Text_IO;

   use type CL.Size;

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

   DT   : CL.Platforms.Device_Kind;
   Fpc  : CL.Platforms.Floating_Point_Config;
   Ecs  : CL.Platforms.Capability_Vector;
   Cqps : CL.Platforms.CQ_Property_Vector;
begin
   AUnit.Assertions.Assert
     (Dvs'Length > 0, "The selected OpenCL platform has no devices");

   for Index in Dvs'Range loop
      IO.Put_Line (Item => "Device" & Index'Img);

      DT := Dvs (Index).Kind;
      AUnit.Assertions.Assert
        (DT.Default or else DT.CPU or else DT.GPU or else DT.Accelerator,
         "Device" & Index'Image & " has no reported device kind");
      IO.Put (Item => "Type: ");
      if DT.Default then
         IO.Put (Item => "Default ");
      end if;
      if DT.CPU then
         IO.Put (Item => "CPU ");
      end if;
      if DT.GPU then
         IO.Put (Item => "GPU ");
      end if;
      if DT.Accelerator then
         IO.Put (Item => "Accelerator");
      end if;
      IO.New_Line;

      IO.Put (Item => "Name: ");
      IO.Put_Line (Dvs (Index).Name);
      AUnit.Assertions.Assert
        (Dvs (Index).Name'Length > 0,
         "Device" & Index'Image & " has an empty name");

      IO.Put (Item => "Vendor: ");
      IO.Put_Line (Dvs (Index).Vendor);
      AUnit.Assertions.Assert
        (Dvs (Index).Vendor'Length > 0,
         "Device" & Index'Image & " has an empty vendor");

      IO.Put (Item => "Version: ");
      IO.Put_Line (Dvs (Index).Version);
      AUnit.Assertions.Assert
        (Dvs (Index).Version'Length > 0,
         "Device" & Index'Image & " has an empty version");

      IO.Put (Item => "Extensions: ");
      IO.Put_Line (Dvs (Index).Extensions);

      Ada.Text_IO.Put (Item => "MAX_WORK_ITEM_SIZES: (");
      declare
         Sizes : constant CL.Size_List := Dvs (Index).Max_Work_Item_Sizes;
      begin
         AUnit.Assertions.Assert
           (Sizes'Length =
              Natural (Dvs (Index).Max_Work_Item_Dimensions),
            "Device" & Index'Image &
              " returned the wrong number of work-item dimensions");
         AUnit.Assertions.Assert
           (Sizes'Length > 0,
            "Device" & Index'Image & " has no work-item dimensions");

         for Size in Sizes'Range loop
            AUnit.Assertions.Assert
              (Sizes (Size) > 0,
               "Device" & Index'Image &
                 " has a zero maximum work-item size");
            if Size /= Sizes'Last then
               Ada.Text_IO.Put (Item => Size'Img & ", ");
            else
               Ada.Text_IO.Put_Line (Item => Size'Img & ")");
            end if;
         end loop;
      end;

      Ada.Text_IO.Put (Item => "MAX_WORK_GROUP_SIZE: ");
      Ada.Text_IO.Put_Line (Dvs (Index).Max_Work_Group_Size'Img);
      AUnit.Assertions.Assert
        (Dvs (Index).Max_Work_Group_Size > 0,
         "Device" & Index'Image & " has a zero maximum work-group size");

      Ada.Text_IO.Put (Item => "SINGLE_FLOATING_POINT_CONFIG: ");
      Fpc := Dvs (Index).Single_Floating_Point_Config;
      if Fpc.Denorm then
         Ada.Text_IO.Put (Item => "Denorm ");
      end if;
      if Fpc.Inf_Man then
         Ada.Text_IO.Put (Item => "Inf_Man ");
      end if;
      if Fpc.Round_To_Zero then
         Ada.Text_IO.Put (Item => "Round_To_Zero ");
      end if;
      if Fpc.Round_To_Nearest then
         Ada.Text_IO.Put (Item => "Round_To_Nearest ");
      end if;
      if Fpc.Round_To_Inf then
         Ada.Text_IO.Put (Item => "Round_To_Inf ");
      end if;
      if Fpc.FMA then
         Ada.Text_IO.Put (Item => "FMA ");
      end if;
      if Fpc.Soft_Float then
         Ada.Text_IO.Put (Item => "Soft_Float");
      end if;
      Ada.Text_IO.New_Line;

      Ada.Text_IO.Put (Item => "MEMORY_CACHE_TYPE: ");
      Ada.Text_IO.Put_Line (Dvs (Index).Memory_Cache_Type'Img);

      Ada.Text_IO.Put (Item => "LOCAL_MEMORY_TYPE: ");
      Ada.Text_IO.Put_Line (Dvs (Index).Local_Memory_Type'Img);

      Ada.Text_IO.Put (Item => "EXECUTION_CAPABILITIES: ");
      Ecs := Dvs (Index).Execution_Capabilities;
      AUnit.Assertions.Assert
        (Ecs.Kernel,
         "Device" & Index'Image & " cannot execute OpenCL kernels");
      if Ecs.Kernel then
         Ada.Text_IO.Put (Item => "Kernel ");
      end if;
      if Ecs.Native_Kernel then
         Ada.Text_IO.Put (Item => "Native_Kernel");
      end if;
      Ada.Text_IO.New_Line;

      Ada.Text_IO.Put (Item => "QUEUE_PROPERTIES: ");
      Cqps := Dvs (Index).Command_Queue_Properties;
      if Cqps.Out_Of_Order_Exec_Mode_Enable then
         Ada.Text_IO.Put (Item => "Out_Of_Order_Exec_Mode_Enable ");
      end if;
      if Cqps.Profiling_Enable then
         Ada.Text_IO.Put (Item => "Profiling_Enable");
      end if;
      Ada.Text_IO.New_Line;

      Ada.Text_IO.Put_Line (Item => Ada.Strings.Fixed."*" (80, '-'));
   end loop;
end CL_Test.Device;