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

procedure CL_Test.Vector_Passing is
   package IO renames Ada.Text_IO;

   use CL.Vectors;

   Destination_List : aliased constant Int2_Array :=
     New_Array ([1 => [0, 0]]);

   package Int2_Objects is
     new CL.Queueing.Memory_Objects
       (Element      => CL.Vectors.Int2,
        Element_List => Int2_Array);

   Platform    : CL.Platforms.Platform;
   Device      : CL.Platforms.Device;
   Device_List : CL.Platforms.Device_List (1 .. 1);
   Context     : CL.Contexts.Context;
   Destination : CL.Memory.Buffers.Buffer;
   Program     : CL.Programs.Program;
   Kernel      : CL.Kernels.Kernel;
   Queue       : CL.Command_Queues.Queue;
   Event       : CL.Events.Event;

   Kernel_File : IO.File_Type;

   use type CL.Int;
   use type CL.Size;

   procedure Set_Input is
     new CL.Kernels.Set_Kernel_Argument
       (Argument_Type  => Int2,
        Argument_Index => 0);
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
   Destination :=
     CL.Memory.Buffers.Constructors.Create
       (Context,
        CL.Memory.Write_Only,
        CL.Vectors.Int2'Size / System.Storage_Unit);
   Queue :=
     CL.Command_Queues.Constructors.Create
       (Context,
        Device,
        CL.Platforms.CQ_Property_Vector'(Reserved => [others => False],
                                         others   => False));

   IO.Open (File => Kernel_File,
            Mode => IO.In_File,
            Name => "src/vector_passing.cl");
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
   Set_Input (Kernel, CL_Vector (7, 42));
   Kernel.Set_Kernel_Argument_Object (1, Destination);
   Event := CL.Queueing.Execute_Task (Queue, Kernel, null);
   Event.Wait_For;

   Int2_Objects.Read_Buffer
     (Queue, Destination, True, 0, Destination_List, Event);
   Event.Wait_For;

   AUnit.Assertions.Assert
     (Destination_List'Length = 1,
      "The vector-passing kernel returned the wrong result count");
   AUnit.Assertions.Assert
     (Destination_List (Destination_List'First).S (0) = 7,
      "The vector-passing kernel returned the wrong first component");
   AUnit.Assertions.Assert
     (Destination_List (Destination_List'First).S (1) = 42,
      "The vector-passing kernel returned the wrong second component");

   IO.Put (Item => "Output: (");
   for Index in Destination_List'Range loop
      IO.Put
        ("(" & Destination_List (Index).S (0)'Img & "," &
         Destination_List (Index).S (1)'Img & "),");
   end loop;
   IO.Put_Line (Item => ")");
end CL_Test.Vector_Passing;