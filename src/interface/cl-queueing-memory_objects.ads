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

with CL.Memory.Images;
with CL.Memory.Buffers;

generic
   type Element is private;
   type Element_List is array (Integer range <>) of Element;
package CL.Queueing.Memory_Objects is
   type Size_Vector2D is array (1 .. 2) of aliased Size;
   type Size_Vector3D is array (1 .. 3) of aliased Size;

   type Mapped_Region is record
      Address     : System.Address := System.Null_Address;
      Row_Pitch   : Size := 0;
      Slice_Pitch : Size := 0;
   end record;

   procedure Read_Buffer (Target_Queue : Command_Queues.Queue'Class;
                          Buffer       : Memory.Buffers.Buffer'Class;
                          Blocking     : Boolean;
                          Offset       : Size;
                          Destination  : Element_List;
                          Ready        : out Events.Event;
                          Wait_For     : Events.Event_List := Events.No_Events);

   procedure Write_Buffer (Target_Queue : Command_Queues.Queue'Class;
                           Buffer       : Memory.Buffers.Buffer'Class;
                           Blocking     : Boolean;
                           Offset       : Size;
                           Source       : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events);

   procedure Copy_Buffer (Target_Queue  : Command_Queues.Queue'Class;
                          Source        : Memory.Buffers.Buffer'Class;
                          Destination   : Memory.Buffers.Buffer'Class;
                          Source_Offset : Size;
                          Dest_Offset   : Size;
                          Num_Elements  : Size;
                          Ready         : out Events.Event;
                          Wait_For      : Events.Event_List := Events.No_Events);

   procedure Read_Buffer_Rect
     (Target_Queue       : Command_Queues.Queue'Class;
      Buffer             : Memory.Buffers.Buffer'Class;
      Blocking           : Boolean;
      Buffer_Origin      : Size_Vector3D;
      Host_Origin        : Size_Vector3D;
      Region             : Size_Vector3D;
      Buffer_Row_Pitch   : Size;
      Buffer_Slice_Pitch : Size;
      Host_Row_Pitch     : Size;
      Host_Slice_Pitch   : Size;
      Destination        : Element_List;
      Ready              : out Events.Event;
      Wait_For           : Events.Event_List := Events.No_Events);

   procedure Write_Buffer_Rect
     (Target_Queue       : Command_Queues.Queue'Class;
      Buffer             : Memory.Buffers.Buffer'Class;
      Blocking           : Boolean;
      Buffer_Origin      : Size_Vector3D;
      Host_Origin        : Size_Vector3D;
      Region             : Size_Vector3D;
      Buffer_Row_Pitch   : Size;
      Buffer_Slice_Pitch : Size;
      Host_Row_Pitch     : Size;
      Host_Slice_Pitch   : Size;
      Source             : Element_List;
      Ready              : out Events.Event;
      Wait_For           : Events.Event_List := Events.No_Events);

   procedure Copy_Buffer_Rect
     (Target_Queue       : Command_Queues.Queue'Class;
      Source             : Memory.Buffers.Buffer'Class;
      Destination        : Memory.Buffers.Buffer'Class;
      Source_Origin      : Size_Vector3D;
      Dest_Origin        : Size_Vector3D;
      Region             : Size_Vector3D;
      Source_Row_Pitch   : Size;
      Source_Slice_Pitch : Size;
      Dest_Row_Pitch     : Size;
      Dest_Slice_Pitch   : Size;
      Ready              : out Events.Event;
      Wait_For           : Events.Event_List := Events.No_Events);

   procedure Fill_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Buffer       : Memory.Buffers.Buffer'Class;
      Pattern      : Element;
      Offset       : Size;
      Num_Elements : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events);

   procedure Read_Image2D (Target_Queue : Command_Queues.Queue'Class;
                           Image        : Memory.Images.Image2D'Class;
                           Blocking     : Boolean;
                           Origin       : Size_Vector2D;
                           Region       : Size_Vector2D;
                           Row_Pitch    : Size;
                           Destination  : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events);

   procedure Read_Image3D (Target_Queue : Command_Queues.Queue'Class;
                           Image        : Memory.Images.Image3D'Class;
                           Blocking     : Boolean;
                           Origin       : Size_Vector3D;
                           Region       : Size_Vector3D;
                           Row_Pitch    : Size;
                           Slice_Pitch  : Size;
                           Destination  : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events);

   procedure Write_Image2D (Target_Queue : Command_Queues.Queue'Class;
                            Image        : Memory.Images.Image2D'Class;
                            Blocking     : Boolean;
                            Origin       : Size_Vector2D;
                            Region       : Size_Vector2D;
                            Row_Pitch    : Size;
                            Source       : Element_List;
                            Ready        : out Events.Event;
                            Wait_For     : Events.Event_List := Events.No_Events);

   procedure Write_Image3D (Target_Queue : Command_Queues.Queue'Class;
                            Image        : Memory.Images.Image3D'Class;
                            Blocking     : Boolean;
                            Origin       : Size_Vector3D;
                            Region       : Size_Vector3D;
                            Row_Pitch    : Size;
                            Slice_Pitch  : Size;
                            Source       : Element_List;
                            Ready        : out Events.Event;
                            Wait_For     : Events.Event_List := Events.No_Events);

   procedure Copy_Image2D (Target_Queue : Command_Queues.Queue'Class;
                           Source       : Memory.Images.Image2D'Class;
                           Destination  : Memory.Images.Image2D'Class;
                           Src_Origin   : Size_Vector2D;
                           Dest_Origin  : Size_Vector2D;
                           Region       : Size_Vector2D;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events);

   procedure Copy_Image3D (Target_Queue : Command_Queues.Queue'Class;
                           Source       : Memory.Images.Image3D'Class;
                           Destination  : Memory.Images.Image3D'Class;
                           Src_Origin   : Size_Vector3D;
                           Dest_Origin  : Size_Vector3D;
                           Region       : Size_Vector3D;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events);

   procedure Copy_Image_To_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Source       : Memory.Images.Image'Class;
      Destination  : Memory.Buffers.Buffer'Class;
      Source_Origin : Size_Vector3D;
      Region       : Size_Vector3D;
      Dest_Offset  : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events);

   procedure Copy_Buffer_To_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Source       : Memory.Buffers.Buffer'Class;
      Destination  : Memory.Images.Image'Class;
      Source_Offset : Size;
      Dest_Origin  : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events);

   procedure Fill_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Image        : Memory.Images.Image'Class;
      Color        : Element;
      Origin       : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events);

   function Map_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Buffer       : Memory.Buffers.Buffer'Class;
      Blocking     : Boolean;
      Flags        : Map_Flags;
      Offset       : Size;
      Byte_Count   : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Mapped_Region;

   function Map_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Image        : Memory.Images.Image'Class;
      Blocking     : Boolean;
      Flags        : Map_Flags;
      Origin       : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Mapped_Region;

   procedure Unmap
     (Target_Queue : Command_Queues.Queue'Class;
      Object       : Memory.Memory_Object'Class;
      Mapped       : Mapped_Region;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events);
end CL.Queueing.Memory_Objects;
