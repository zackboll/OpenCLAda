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

with CL.Command_Queues;
with CL.Contexts;
with CL.Events;
with CL.Kernels;
with CL.Memory.Buffers;
with CL.Platforms;
with CL.Programs;
with CL.Queueing;
with CL.Queueing.Memory_Objects;

with CL_Test.Helpers;

procedure CL_Test.Hello_World is
   package IO renames Ada.Text_IO;

   type Aliased_String is array (Integer range <>) of aliased Character;

   function String_Buffer is
     new CL.Memory.Buffers.Constructors.Create_From_Source
       (Element      => Character,
        Element_List => Aliased_String);

   package String_Objects is
     new CL.Queueing.Memory_Objects
       (Element      => Character,
        Element_List => Aliased_String);

   Platform    : CL.Platforms.Platform;
   Device      : CL.Platforms.Device;
   Device_List : CL.Platforms.Device_List (1 .. 1);
   Context     : CL.Contexts.Context;
   Buffer      : CL.Memory.Buffers.Buffer;
   Program     : CL.Programs.Program;
   Kernel      : CL.Kernels.Kernel;
   Queue       : CL.Command_Queues.Queue;
   Event       : CL.Events.Event;

   Hello_World : constant String := "Hello world!";
   Output      : aliased constant Aliased_String :=
     [Hello_World'Range => <>];

   Kernel_File : IO.File_Type;

   Global_Work_Size : aliased CL.Size_List := [1 => Hello_World'Length];
   Local_Work_Size  : aliased CL.Size_List := [1 => 1];
begin
   IO.Put_Line (Item => "Gathering platform and devices");
   declare
      Platforms : constant CL.Platforms.Platform_List := CL.Platforms.List;
   begin
      AUnit.Assertions.Assert
        (Platforms'Length > 0, "No OpenCL platform was found");
      Platform := Platforms (Platforms'First);
   end;

   declare
      Devices : constant CL.Platforms.Device_List :=
        Platform.Devices (CL.Platforms.Device_Kind_All);
   begin
      AUnit.Assertions.Assert
        (Devices'Length > 0, "The selected OpenCL platform has no devices");
      Device := Devices (Devices'First);
   end;
   Device_List := [1 => Device];

   IO.Put_Line (Item => "Creating context");
   Context :=
     CL.Contexts.Constructors.Create_For_Devices (Platform, [1 => Device]);

   IO.Put_Line (Item => "Creating buffer");
   Buffer := String_Buffer (Context, CL.Memory.Write_Only, Output);

   IO.Put_Line (Item => "Compiling kernel source");
   IO.Open
     (File => Kernel_File,
      Mode => IO.In_File,
      Name => "src/hello-kernel.cl");
   declare
      Kernel_Source : constant String :=
        CL_Test.Helpers.Read_File (Kernel_File);
   begin
      IO.Close (File => Kernel_File);
      Program :=
        CL.Programs.Constructors.Create_From_Source (Context, Kernel_Source);
   end;

   Program.Build (Device_List, "", null);
   IO.Put_Line (Item => "Creating kernel");
   Kernel := CL.Kernels.Constructors.Create (Program, "hello");

   IO.Put_Line (Item => "Setting kernel argument");
   CL.Kernels.Set_Kernel_Argument_Object (Kernel, 0, Buffer);

   IO.Put_Line (Item => "Creating queue");
   Queue :=
     CL.Command_Queues.Constructors.Create
       (Context,
        Device,
        CL.Platforms.CQ_Property_Vector'
          (Out_Of_Order_Exec_Mode_Enable    => False,
           Profiling_Enable                 => False,
           Reserved                         => [others => False]));

   IO.Put_Line (Item => "Queueing kernel");
   Event :=
     CL.Queueing.Execute_Kernel
       (Queue,
        Kernel,
        1,
        Global_Work_Size'Access,
        Local_Work_Size'Access,
        null);
   Event.Wait_For;

   IO.Put_Line (Item => "Retrieving result");
   String_Objects.Read_Buffer (Queue, Buffer, True, 0, Output, Event);
   Event.Wait_For;

   IO.Put_Line (Item => String (Output));
   AUnit.Assertions.Assert
     (String (Output) = "Hello World!",
      "The hello-world kernel returned """ & String (Output) & """");
end CL_Test.Hello_World;
