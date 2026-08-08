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
with System;

with AUnit.Assertions;

with CL.Command_Queues;
with CL.Contexts;
with CL.Events;
with CL.Kernels;
with CL.Memory.Buffers;
with CL.Platforms;
with CL.Programs;
with CL.Queueing;
with CL.Queueing.Memory_Objects;
with CL.Vectors;

with CL_Test.Helpers;

procedure CL_Test.Vectors is
   package IO renames Ada.Text_IO;

   use CL.Vectors;

   Source1_List : aliased constant Int2_Array :=
     New_Array ([[1, 2], [3, 4], [5, 6], [7, 8], [9, 0]]);
   Source2_List : aliased constant Int2_Array :=
     New_Array ([[0, 9], [2, 7], [4, 5], [6, 3], [8, 1]]);
   Destination_List : aliased constant Int2_Array :=
     New_Array ([Source1_List'Range => [0, 0]]);

   function Int2_Buffer is
     new CL.Memory.Buffers.Constructors.Create_From_Source
       (Element      => CL.Vectors.Int2,
        Element_List => Int2_Array);

   package Int2_Objects is
     new CL.Queueing.Memory_Objects
       (Element      => CL.Vectors.Int2,
        Element_List => Int2_Array);

   Platform    : CL.Platforms.Platform;
   Device      : CL.Platforms.Device;
   Device_List : CL.Platforms.Device_List (1 .. 1);
   Context     : CL.Contexts.Context;
   Source1     : CL.Memory.Buffers.Buffer;
   Source2     : CL.Memory.Buffers.Buffer;
   Destination : CL.Memory.Buffers.Buffer;
   Program     : CL.Programs.Program;
   Kernel      : CL.Kernels.Kernel;
   Queue       : CL.Command_Queues.Queue;
   Event       : CL.Events.Event;

   Kernel_File : IO.File_Type;

   Global_Work_Size : aliased CL.Size_List := [1 => Source1_List'Length];
   Local_Work_Size  : aliased CL.Size_List := [1 => 1];

   use type CL.Int;
   use type CL.Size;
begin
   declare
      Platforms : constant CL.Platforms.Platform_List := CL.Platforms.List;
   begin
      AUnit.Assertions.Assert
        (Platforms'Length > 0, "No OpenCL platform was found");
      Platform := Platforms (Platforms'First);
   end;

   declare
      Devices : constant CL.Platforms.Device_List :=
        Platform.Devices
          (CL.Platforms.Device_Kind'(GPU      => True,
                                     Reserved => [others => False],
                                     others   => False));
   begin
      AUnit.Assertions.Assert
        (Devices'Length > 0, "The selected OpenCL platform has no GPU device");
      Device := Devices (Devices'First);
   end;
   Device_List := [1 => Device];
   Context :=
     CL.Contexts.Constructors.Create_For_Devices (Platform, Device_List);
   Source1 := Int2_Buffer (Context, CL.Memory.Read_Only, Source1_List);
   Source2 := Int2_Buffer (Context, CL.Memory.Read_Only, Source2_List);
   Destination :=
     CL.Memory.Buffers.Constructors.Create
       (Context,
        CL.Memory.Write_Only,
        CL.Vectors.Int2'Size / System.Storage_Unit * Source1_List'Length);
   Queue :=
     CL.Command_Queues.Constructors.Create
       (Context,
        Device,
        CL.Platforms.CQ_Property_Vector'(Reserved => [others => False],
                                         others   => False));

   IO.Open (File => Kernel_File, Mode => IO.In_File, Name => "src/vectors.cl");
   declare
      Kernel_Source : constant String :=
        CL_Test.Helpers.Read_File (Kernel_File);
   begin
      IO.Close (File => Kernel_File);
      Program :=
        CL.Programs.Constructors.Create_From_Source (Context, Kernel_Source);
   end;

   Program.Build (Device_List, "", null);
   Kernel := CL.Kernels.Constructors.Create (Program, "add");
   Kernel.Set_Kernel_Argument_Object (0, Source1);
   Kernel.Set_Kernel_Argument_Object (1, Source2);
   Kernel.Set_Kernel_Argument_Object (2, Destination);
   Event :=
     CL.Queueing.Execute_Kernel
       (Queue,
        Kernel,
        1,
        Global_Work_Size'Access,
        Local_Work_Size'Access,
        null);
   Event.Wait_For;

   Int2_Objects.Read_Buffer
     (Queue, Destination, True, 0, Destination_List, Event);
   Event.Wait_For;

   AUnit.Assertions.Assert
     (Destination_List'Length = Source1_List'Length,
      "The vector kernel returned the wrong result count");
   for Index in Destination_List'Range loop
      for Component in CL.Range2 loop
         AUnit.Assertions.Assert
           (Destination_List (Index).S (Component) =
              Source1_List (Index).S (Component) +
                Source2_List (Index).S (Component),
            "The vector kernel returned the wrong value at result" &
              Index'Image & ", component" & Component'Image);
      end loop;
   end loop;

   IO.Put (Item => "Output: (");
   for Index in Destination_List'Range loop
      IO.Put
        ("(" & Destination_List (Index).S (0)'Img & "," &
         Destination_List (Index).S (1)'Img & "),");
   end loop;
   IO.Put_Line (Item => ")");
end CL_Test.Vectors;