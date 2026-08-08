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

package body CL.Queueing.Memory_Objects is
   Element_Bytes : constant Size := Element'Size / System.Storage_Unit;

   procedure Read_Buffer (Target_Queue : Command_Queues.Queue'Class;
                          Buffer       : Memory.Buffers.Buffer'Class;
                          Blocking     : Boolean;
                          Offset       : Size;
                          Destination  : Element_List;
                          Ready        : out Events.Event;
                          Wait_For     : Events.Event_List := Events.No_Events) is

      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Read_Buffer
              (Queue      => CL_Object (Target_Queue).Location,
               Buffer     => CL_Object (Buffer).Location,
               Blocking   => CL.Bool (Blocking),
               Offset     => Offset,
               CB         => Destination'Length * Element_Bytes,
               Ptr        => Destination (Destination'First)'Address,
               Num_Events => Raw_List'Length,
               Event_List => Raw_List (1)'Unchecked_Access,
               Event      => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Read_Buffer
           (Queue      => CL_Object (Target_Queue).Location,
            Buffer     => CL_Object (Buffer).Location,
            Blocking   => CL.Bool (Blocking), 
            Offset     => Offset,
            CB         => Destination'Length * Element_Bytes,
            Ptr        => Destination (Destination'First)'Address,
            Num_Events => 0, 
            Event_List => null, 
            Event      => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                           Location => Ret_Event);
   end Read_Buffer;
   
   procedure Write_Buffer (Target_Queue : Command_Queues.Queue'Class;
                           Buffer       : Memory.Buffers.Buffer'Class;
                           Blocking     : Boolean;
                           Offset       : Size;
                           Source       : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Write_Buffer
              (Queue      => CL_Object (Target_Queue).Location,
               Buffer     => CL_Object (Buffer).Location,
               Blocking   => CL.Bool (Blocking),
               Offset     => Offset,
               Byte_Count => Source'Length * Element_Bytes,
               Source     => Source (Source'First)'Address,
               Wait_Count => Raw_List'Length,
               Wait_List  => Raw_List (1)'Unchecked_Access,
               Event      => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Write_Buffer
              (Queue      => CL_Object (Target_Queue).Location,
               Buffer     => CL_Object (Buffer).Location,
               Blocking   => CL.Bool (Blocking), 
               Offset     => Offset,
               Byte_Count => Source'Length * Element_Bytes,
               Source     => Source (Source'First)'Address,
               Wait_Count => 0, 
               Wait_List  => null, 
               Event      => Ret_Event'Unchecked_Access);
      end if;

      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Write_Buffer;

   procedure Copy_Buffer (Target_Queue  : Command_Queues.Queue'Class;
                          Source        : Memory.Buffers.Buffer'Class;
                          Destination   : Memory.Buffers.Buffer'Class;
                          Source_Offset : Size;
                          Dest_Offset   : Size;
                          Num_Elements  : Size;
                          Ready         : out Events.Event;
                          Wait_For      : Events.Event_List := Events.No_Events) is
      Raw_List  : Address_List := Raw_Event_List (Wait_For);
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      Error := API.Enqueue_Copy_Buffer 
        (Queue       => CL_Object (Target_Queue).Location,
         Source      => CL_Object (Source).Location,
         Destination => CL_Object (Destination).Location,
         Src_Offset  => Source_Offset, 
         Dst_Offset  => Dest_Offset, 
         Byte_Count  => Num_Elements,
         Wait_Count  => Raw_List'Length,
         Wait_List   => Raw_List (1)'Unchecked_Access,
         Event       => Ret_Event'Unchecked_Access);
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Buffer;

   procedure Read_Image2D (Target_Queue : Command_Queues.Queue'Class;
                           Image        : Memory.Images.Image2D'Class;
                           Blocking     : Boolean;
                           Origin       : Size_Vector2D;
                           Region       : Size_Vector2D;
                           Row_Pitch    : Size;
                           Destination  : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events) is

      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
      Origin_3D : Size_Vector3D := [1 => Origin (1), 2 => Origin (2), 3 => 0];
      Region_3D : Size_Vector3D := [1 => Region (1), 2 => Region (2), 3 => 1];
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Read_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin_3D (1)'Unchecked_Access,
               Region      => Region_3D (1)'Unchecked_Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => 0,
               Ptr         => Destination (Destination'First)'Address,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Read_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin_3D (1)'Unchecked_Access,
               Region      => Region_3D (1)'Unchecked_Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => 0,
               Ptr         => Destination (Destination'First)'Address,
               Num_Events  => 0, 
               Event_List  => null, 
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error => Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Read_Image2D;

   procedure Read_Image3D (Target_Queue : Command_Queues.Queue'Class;
                           Image        : Memory.Images.Image3D'Class;
                           Blocking     : Boolean;
                           Origin       : Size_Vector3D;
                           Region       : Size_Vector3D;
                           Row_Pitch    : Size;
                           Slice_Pitch  : Size;
                           Destination  : Element_List;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Read_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking), Origin      => Origin (1)'Access,
               Region      => Region (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => Slice_Pitch,
               Ptr         => Destination (Destination'First)'Address,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Read_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking), 
               Origin      => Origin (1)'Access,
               Region      => Region (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => Slice_Pitch,
               Ptr         => Destination (Destination'First)'Address,
               Num_Events  => 0, 
               Event_List  => null, 
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Read_Image3D;

   procedure Write_Image2D (Target_Queue : Command_Queues.Queue'Class;
                            Image        : Memory.Images.Image2D'Class;
                            Blocking     : Boolean;
                            Origin       : Size_Vector2D;
                            Region       : Size_Vector2D;
                            Row_Pitch    : Size;
                            Source       : Element_List;
                            Ready        : out Events.Event;
                            Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
      Origin_3D : Size_Vector3D := [1 => Origin (1), 2 => Origin (2), 3 => 0];
      Region_3D : Size_Vector3D := [1 => Region (1), 2 => Region (2), 3 => 1];
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Write_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin_3D (1)'Access,
               Region      => Region_3D (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => 0,
               Ptr         => Source (Source'First)'Address,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Write_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin_3D (1)'Access,
               Region      => Region_3D (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => 0,
               Ptr         => Source (Source'First)'Address,
               Num_Events  => 0, 
               Event_List  => null, 
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Write_Image2D;

   procedure Write_Image3D (Target_Queue : Command_Queues.Queue'Class;
                            Image        : Memory.Images.Image3D'Class;
                            Blocking     : Boolean;
                            Origin       : Size_Vector3D;
                            Region       : Size_Vector3D;
                            Row_Pitch    : Size;
                            Slice_Pitch  : Size;
                            Source       : Element_List;
                            Ready        : out Events.Event;
                            Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Write_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin (1)'Access,
               Region      => Region (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => Slice_Pitch,
               Ptr         => Source (Source'First)'Address,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Write_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking),
               Origin      => Origin (1)'Access,
               Region      => Region (1)'Access,
               Row_Pitch   => Row_Pitch, 
               Slice_Pitch => Slice_Pitch,
               Ptr         => Source (Source'First)'Address,
               Num_Events  => 0, 
               Event_List  => null, 
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Write_Image3D;

   procedure Copy_Image2D (Target_Queue : Command_Queues.Queue'Class;
                           Source       : Memory.Images.Image2D'Class;
                           Destination  : Memory.Images.Image2D'Class;
                           Src_Origin   : Size_Vector2D;
                           Dest_Origin  : Size_Vector2D;
                           Region       : Size_Vector2D;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
      Src_Origin_3D : Size_Vector3D := [1 => Src_Origin (1),
                                        2 => Src_Origin (2), 3 => 0];
      Dest_Origin_3D : Size_Vector3D := [1 => Dest_Origin (1),
                                         2 => Dest_Origin (2), 3 => 0];
      Region_3D : Size_Vector3D := [1 => Region (1), 2 => Region (2), 3 => 1];
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Copy_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Source      => CL_Object (Source).Location,
               Dest        => CL_Object (Destination).Location,
               Src_Origin  => Src_Origin_3D (1)'Access,
               Dest_Origin => Dest_Origin_3D (1)'Access,
               Region      => Region_3D (1)'Access,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Copy_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Source      => CL_Object (Source).Location,
               Dest        => CL_Object (Destination).Location,
               Src_Origin  => Src_Origin_3D (1)'Access,
               Dest_Origin => Dest_Origin_3D (1)'Access,
               Region      => Region_3D (1)'Access,
               Num_Events  => 0, 
               Event_List  => null, 
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Image2D;

   procedure Copy_Image3D (Target_Queue : Command_Queues.Queue'Class;
                           Source       : Memory.Images.Image3D'Class;
                           Destination  : Memory.Images.Image3D'Class;
                           Src_Origin   : Size_Vector3D;
                           Dest_Origin  : Size_Vector3D;
                           Region       : Size_Vector3D;
                           Ready        : out Events.Event;
                           Wait_For     : Events.Event_List := Events.No_Events) is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length > 0 then
         declare
            Raw_List  : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Copy_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Source      => CL_Object (Source).Location,
               Dest        => CL_Object (Destination).Location,
               Src_Origin  => Src_Origin (1)'Access,
               Dest_Origin => Dest_Origin (1)'Access,
               Region      => Region (1)'Access,
               Num_Events  => Raw_List'Length,
               Event_List  => Raw_List (1)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Copy_Image
              (Queue       => CL_Object (Target_Queue).Location,
               Source      => CL_Object (Source).Location,
               Dest        => CL_Object (Destination).Location,
               Src_Origin  => Src_Origin (1)'Access,
               Dest_Origin => Dest_Origin (1)'Access,
               Region      => Region (1)'Access,
               Num_Events  => 0,
               Event_List  => null,
               Event       => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error => Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Image3D;

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
      Wait_For           : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Read_Buffer_Rect
           (Queue              => CL_Object (Target_Queue).Location, 
            Buffer             => CL_Object (Buffer).Location,
            Blocking           => CL.Bool (Blocking), 
            Buffer_Origin      => Buffer_Origin'Address, 
            Host_Origin        => Host_Origin'Address,
            Region             => Region'Address, 
            Buffer_Row_Pitch   => Buffer_Row_Pitch, 
            Buffer_Slice_Pitch => Buffer_Slice_Pitch,
            Host_Row_Pitch     => Host_Row_Pitch, 
            Host_Slice_Pitch   => Host_Slice_Pitch,
            Destination        => Destination (Destination'First)'Address, 
            Wait_Count         => 0, 
            Wait_List          => System.Null_Address,
            Event              => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Read_Buffer_Rect
              (Queue              => CL_Object (Target_Queue).Location, 
               Buffer             => CL_Object (Buffer).Location,
               Blocking           => CL.Bool (Blocking), 
               Buffer_Origin      => Buffer_Origin'Address, 
               Host_Origin        => Host_Origin'Address,
               Region             => Region'Address, 
               Buffer_Row_Pitch   => Buffer_Row_Pitch, 
               Buffer_Slice_Pitch => Buffer_Slice_Pitch,
               Host_Row_Pitch     => Host_Row_Pitch, 
               Host_Slice_Pitch   => Host_Slice_Pitch,
               Destination        => Destination (Destination'First)'Address,
               Wait_Count         => UInt (Raw_Wait'Length), 
               Wait_List          => Raw_Wait (Raw_Wait'First)'Address,
               Event              => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Read_Buffer_Rect;

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
      Wait_For           : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Write_Buffer_Rect
           (Queue              => CL_Object (Target_Queue).Location, 
            Buffer             => CL_Object (Buffer).Location,
            Blocking           => CL.Bool (Blocking), 
            Buffer_Origin      => Buffer_Origin'Address, 
            Host_Origin        => Host_Origin'Address,
            Region             => Region'Address, 
            Buffer_Row_Pitch   => Buffer_Row_Pitch, 
            Buffer_Slice_Pitch => Buffer_Slice_Pitch,
            Host_Row_Pitch     => Host_Row_Pitch, 
            Host_Slice_Pitch   => Host_Slice_Pitch,
            Source             => Source (Source'First)'Address, 
            Wait_Count         => 0, 
            Wait_List          => System.Null_Address,
            Event              => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Write_Buffer_Rect
              (Queue              => CL_Object (Target_Queue).Location, 
               Buffer             => CL_Object (Buffer).Location,
               Blocking           => CL.Bool (Blocking), 
               Buffer_Origin      => Buffer_Origin'Address, 
               Host_Origin        => Host_Origin'Address,
               Region             => Region'Address, 
               Buffer_Row_Pitch   => Buffer_Row_Pitch, 
               Buffer_Slice_Pitch => Buffer_Slice_Pitch,
               Host_Row_Pitch     => Host_Row_Pitch, 
               Host_Slice_Pitch   => Host_Slice_Pitch, 
               Source             => Source (Source'First)'Address,
               Wait_Count         => UInt (Raw_Wait'Length), 
               Wait_List          => Raw_Wait (Raw_Wait'First)'Address,
               Event              => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Write_Buffer_Rect;

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
      Wait_For           : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Copy_Buffer_Rect
           (Queue              => CL_Object (Target_Queue).Location, 
            Source             => CL_Object (Source).Location,
            Destination        => CL_Object (Destination).Location, 
            Source_Origin      => Source_Origin'Address,
            Dest_Origin        => Dest_Origin'Address, 
            Region             => Region'Address, 
            Source_Row_Pitch   => Source_Row_Pitch,
            Source_Slice_Pitch => Source_Slice_Pitch, 
            Dest_Row_Pitch     => Dest_Row_Pitch, 
            Dest_Slice_Pitch   => Dest_Slice_Pitch,
            Wait_Count         => 0,
            Wait_List          => System.Null_Address, 
            Event              => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Copy_Buffer_Rect
              (Queue              => CL_Object (Target_Queue).Location, 
               Source             => CL_Object (Source).Location,
               Destination        => CL_Object (Destination).Location, 
               Source_Origin      => Source_Origin'Address,
               Dest_Origin        => Dest_Origin'Address, 
               Region             => Region'Address, 
               Source_Row_Pitch   => Source_Row_Pitch,
               Source_Slice_Pitch => Source_Slice_Pitch, 
               Dest_Row_Pitch     => Dest_Row_Pitch, 
               Dest_Slice_Pitch   => Dest_Slice_Pitch,
               Wait_Count         => UInt (Raw_Wait'Length), 
               Wait_List          => Raw_Wait (Raw_Wait'First)'Address,
               Event              => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Buffer_Rect;

   procedure Fill_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Buffer       : Memory.Buffers.Buffer'Class;
      Pattern      : Element;
      Offset       : Size;
      Num_Elements : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Fill_Buffer
           (Queue        => CL_Object (Target_Queue).Location, 
            Buffer       => CL_Object (Buffer).Location,
            Pattern      => Pattern'Address, 
            Pattern_Size => Element_Bytes, 
            Offset       => Offset,
            Byte_Count   => Num_Elements * Element_Bytes, 
            Wait_Count   => 0, 
            Wait_List    => System.Null_Address,
            Event        => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Fill_Buffer
              (Queue        => CL_Object (Target_Queue).Location, 
               Buffer       => CL_Object (Buffer).Location,
               Pattern      => Pattern'Address, 
               Pattern_Size => Element_Bytes, 
               Offset       => Offset,
               Byte_Count   => Num_Elements * Element_Bytes, 
               Wait_Count   => UInt (Raw_Wait'Length),
               Wait_List    => Raw_Wait (Raw_Wait'First)'Address,
               Event        => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Fill_Buffer;

   procedure Copy_Image_To_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Source       : Memory.Images.Image'Class;
      Destination  : Memory.Buffers.Buffer'Class;
      Source_Origin : Size_Vector3D;
      Region       : Size_Vector3D;
      Dest_Offset  : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Copy_Image_To_Buffer
           (Queue       => CL_Object (Target_Queue).Location, 
            Image       => CL_Object (Source).Location,
            Buffer      => CL_Object (Destination).Location,
            Origin      => Source_Origin (1)'Unchecked_Access, 
            Region      => Region (1)'Unchecked_Access,
            Dest_Offset => Dest_Offset, 
            Num_Events  => 0, 
            Event_List  => null, 
            Event       => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Copy_Image_To_Buffer
              (Queue       => CL_Object (Target_Queue).Location, 
               Image       => CL_Object (Source).Location,
               Buffer      => CL_Object (Destination).Location,
               Origin      => Source_Origin (1)'Unchecked_Access, 
               Region      => Region (1)'Unchecked_Access,
               Dest_Offset => Dest_Offset, 
               Num_Events  => UInt (Raw_Wait'Length),
               Event_List  => Raw_Wait (Raw_Wait'First)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Image_To_Buffer;

   procedure Copy_Buffer_To_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Source       : Memory.Buffers.Buffer'Class;
      Destination  : Memory.Images.Image'Class;
      Source_Offset : Size;
      Dest_Origin  : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Copy_Buffer_To_Image
           (Queue      => CL_Object (Target_Queue).Location, 
            Buffer     => CL_Object (Source).Location,
            Image      => CL_Object (Destination).Location, 
            Src_Offset => Source_Offset,
            Origin     => Dest_Origin (1)'Unchecked_Access, 
            Region     => Region (1)'Unchecked_Access,
            Num_Events => 0, 
            Event_List => null, 
            Event      => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Copy_Buffer_To_Image
              (Queue      => CL_Object (Target_Queue).Location, 
               Buffer     => CL_Object (Source).Location,
               Image      => CL_Object (Destination).Location, 
               Src_Offset => Source_Offset,
               Origin     => Dest_Origin (1)'Unchecked_Access, 
               Region     => Region (1)'Unchecked_Access,
               Num_Events => UInt (Raw_Wait'Length),
               Event_List => Raw_Wait (Raw_Wait'First)'Unchecked_Access,
               Event      => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Copy_Buffer_To_Image;

   procedure Fill_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Image        : Memory.Images.Image'Class;
      Color        : Element;
      Origin       : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Fill_Image
           (Queue      => CL_Object (Target_Queue).Location, 
            Image      => CL_Object (Image).Location,
            Fill_Color => Color'Address, 
            Origin     => Origin'Address, 
            Region     => Region'Address, 
            Wait_Count => 0,
            Wait_List  => System.Null_Address, 
            Event      => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Fill_Image
              (Queue      => CL_Object (Target_Queue).Location, 
               Image      => CL_Object (Image).Location,
               Fill_Color => Color'Address, 
               Origin     => Origin'Address, 
               Region     => Region'Address,
               Wait_Count => UInt (Raw_Wait'Length), 
               Wait_List  => Raw_Wait (Raw_Wait'First)'Address,
               Event      => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Fill_Image;

   function Map_Buffer
     (Target_Queue : Command_Queues.Queue'Class;
      Buffer       : Memory.Buffers.Buffer'Class;
      Blocking     : Boolean;
      Flags        : Map_Flags;
      Offset       : Size;
      Byte_Count   : Size;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Mapped_Region
   is
      Error       : aliased Enumerations.Error_Code;
      Ret_Event   : aliased System.Address;
      Raw_Address : System.Address;
   begin
      if Wait_For'Length = 0 then
         Raw_Address := API.Enqueue_Map_Buffer
           (Queue      => CL_Object (Target_Queue).Location, 
            Buffer     => CL_Object (Buffer).Location,
            Blocking   => CL.Bool (Blocking), 
            Map_Flags  => Flags, 
            Offset     => Offset, 
            CB         => Byte_Count, 
            Num_Events => 0, 
            Event_List => null,
            Event      => Ret_Event'Unchecked_Access, 
            Error      => Error'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Raw_Address := API.Enqueue_Map_Buffer
              (Queue       => CL_Object (Target_Queue).Location, 
               Buffer      => CL_Object (Buffer).Location,
               Blocking    => CL.Bool (Blocking), 
               Map_Flags   => Flags, 
               Offset      => Offset, 
               CB          => Byte_Count,
               Num_Events  => UInt (Raw_Wait'Length),
               Event_List  => Raw_Wait (Raw_Wait'First)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access, 
               Error       => Error'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
      return (Address     => Raw_Address, 
              Row_Pitch   => 0, 
              Slice_Pitch => 0);
   end Map_Buffer;

   function Map_Image
     (Target_Queue : Command_Queues.Queue'Class;
      Image        : Memory.Images.Image'Class;
      Blocking     : Boolean;
      Flags        : Map_Flags;
      Origin       : Size_Vector3D;
      Region       : Size_Vector3D;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Mapped_Region
   is
      Error       : aliased Enumerations.Error_Code;
      Ret_Event   : aliased System.Address;
      Row_Pitch   : aliased Size;
      Slice_Pitch : aliased Size;
      Raw_Address : System.Address;
   begin
      if Wait_For'Length = 0 then
         Raw_Address := API.Enqueue_Map_Image
           (Queue       => CL_Object (Target_Queue).Location, 
            Image       => CL_Object (Image).Location,
            Blocking    => CL.Bool (Blocking), 
            Map_Flags   => Flags, 
            Origin      => Origin (1)'Unchecked_Access,
            Region      => Region (1)'Unchecked_Access, 
            Row_Pitch   => Row_Pitch'Unchecked_Access,
            Slice_Pitch => Slice_Pitch'Unchecked_Access, 
            Num_Events  => 0, 
            Event_List  => null,
            Event       => Ret_Event'Unchecked_Access, 
            Error       => Error'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Raw_Address := API.Enqueue_Map_Image
              (Queue       => CL_Object (Target_Queue).Location, 
               Image       => CL_Object (Image).Location,
               Blocking    => CL.Bool (Blocking), 
               Map_Flags   => Flags, 
               Origin      => Origin (1)'Unchecked_Access,
               Region      => Region (1)'Unchecked_Access, 
               Row_Pitch   => Row_Pitch'Unchecked_Access,
               Slice_Pitch => Slice_Pitch'Unchecked_Access, 
               Num_Events  => UInt (Raw_Wait'Length),
               Event_List  => Raw_Wait (Raw_Wait'First)'Unchecked_Access,
               Event       => Ret_Event'Unchecked_Access, 
               Error       => Error'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
      return (Address     => Raw_Address, 
              Row_Pitch   => Row_Pitch,
              Slice_Pitch => Slice_Pitch);
   end Map_Image;

   procedure Unmap
     (Target_Queue : Command_Queues.Queue'Class;
      Object       : Memory.Memory_Object'Class;
      Mapped       : Mapped_Region;
      Ready        : out Events.Event;
      Wait_For     : Events.Event_List := Events.No_Events)
   is
      Error     : Enumerations.Error_Code;
      Ret_Event : aliased System.Address;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Unmap_Mem_Object
           (Queue      => CL_Object (Target_Queue).Location, 
            Memobj     => CL_Object (Object).Location,
            Ptr        => Mapped.Address, 
            Num_Events => 0, 
            Event_List => null, 
            Event      => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Unmap_Mem_Object
              (Queue      => CL_Object (Target_Queue).Location, 
               Memobj     => CL_Object (Object).Location,
               Ptr        => Mapped.Address, 
               Num_Events => UInt (Raw_Wait'Length),
               Event_List => Raw_Wait (Raw_Wait'First)'Unchecked_Access,
               Event      => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      Ready := Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Unmap;
end CL.Queueing.Memory_Objects;
