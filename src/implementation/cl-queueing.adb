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

with Ada.Unchecked_Conversion;

with CL.API;
with CL.Enumerations;

package body CL.Queueing is
   function Execute_Kernel (Target_Queue     : Command_Queues.Queue'Class;
                            Kernel           : Kernels.Kernel'Class;
                            Dimension        : Kernel_Dimension;
                            Global_Work_Size : access constant Size_List;
                            Local_Work_Size  : access constant Size_List;
                            Wait_For         : access Events.Event_List)
                            return Events.Event is
      Local_Work_Size_Ptr : access constant Size;
      Ret_Event           : aliased System.Address;
      Error               : Enumerations.Error_Code;
   begin
      if Global_Work_Size = null or else
        Global_Work_Size.all'First /= 1 or else
        Global_Work_Size.all'Last /= Integer (Dimension) then
         raise Invalid_Global_Work_Size;
      end if;
      if Local_Work_Size /= null then
         if Local_Work_Size.all'First /= 1 or
           Local_Work_Size.all'Last /= Integer (Dimension) then
            raise Invalid_Local_Work_Size;
         end if;
         Local_Work_Size_Ptr := Local_Work_Size.all (Local_Work_Size.all'First)'Access;
      else
         Local_Work_Size_Ptr := null;
      end if;
      if Wait_For /= null and then Wait_For.all'Length > 0 then
         declare
            Raw_List : Address_List := Raw_Event_List (Wait_For.all);
         begin
            Error := API.Enqueue_NDRange_Kernel
              (Queue              => CL_Object (Target_Queue).Location,
               Kernel             => CL_Object (Kernel).Location,
               Work_Dim           => Dimension, 
               Global_Work_Offset => null,
               Global_Work_Size   => Global_Work_Size.all (1)'Access,
               Local_Work_Size    => Local_Work_Size_Ptr,
               Num_Events         => Raw_List'Length,
               Event_List         => Raw_List (1)'Unchecked_Access,
               Event              => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_NDRange_Kernel
           (Queue              => CL_Object (Target_Queue).Location,
            Kernel             => CL_Object (Kernel).Location,
            Work_Dim           => Dimension, 
            Global_Work_Offset => null,
            Global_Work_Size   => Global_Work_Size.all (1)'Access,
            Local_Work_Size    => Local_Work_Size_Ptr,
            Num_Events         => 0,
            Event_List         => null,
            Event              => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Execute_Kernel;

   function Execute_Task (Target_Queue : Command_Queues.Queue'Class;
                          Kernel       : Kernels.Kernel'Class;
                          Wait_For     : access Events.Event_List)
                          return Events.Event is
      Error          : Enumerations.Error_Code;
      Ret_Event      : aliased System.Address;
   begin
      if Wait_For /= null and then Wait_For.all'Length > 0 then
         declare
            Raw_List       : Address_List := Raw_Event_List (Wait_For.all);
         begin
            Error := API.Enqueue_Task (Queue      => CL_Object (Target_Queue).Location,
                                       Kernel     => CL_Object (Kernel).Location,
                                       Num_Events => Raw_List'Length,
                                       Event_List => Raw_List (1)'Unchecked_Access,
                                       Event      => Ret_Event'Unchecked_Access);
         end;
      else
         Error := API.Enqueue_Task (Queue      => CL_Object (Target_Queue).Location,
                                    Kernel     => CL_Object (Kernel).Location,
                                    Num_Events => 0, 
                                    Event_List => null,
                                    Event      => Ret_Event'Unchecked_Access);
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                             Location => Ret_Event);
   end Execute_Task;

   function Marker
     (Target_Queue : Command_Queues.Queue'Class;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event
   is
      Ret_Event : aliased System.Address;
      Error     : Enumerations.Error_Code;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Marker_With_Wait_List
           (Queue      => CL_Object (Target_Queue).Location, 
            Wait_Count => 0, 
            Wait_List  => System.Null_Address,
            Event      => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_List : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Marker_With_Wait_List
              (Queue      => CL_Object (Target_Queue).Location, 
               Wait_Count => UInt (Raw_List'Length),
               Wait_List  => Raw_List (Raw_List'First)'Address,
               Event      => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                           Location => Ret_Event);
   end Marker;

   function Barrier
     (Target_Queue : Command_Queues.Queue'Class;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event
   is
      Ret_Event : aliased System.Address;
      Error     : Enumerations.Error_Code;
   begin
      if Wait_For'Length = 0 then
         Error := API.Enqueue_Barrier_With_Wait_List
           (Queue      => CL_Object (Target_Queue).Location, 
            Wait_Count => 0, 
            Wait_List  => System.Null_Address,
            Event      => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_List : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Barrier_With_Wait_List
              (Queue      => CL_Object (Target_Queue).Location, 
               Wait_Count => UInt (Raw_List'Length),
               Wait_List  => Raw_List (Raw_List'First)'Address,
               Event      => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                           Location => Ret_Event);
   end Barrier;

   function Migrate_Memory_Objects
     (Target_Queue : Command_Queues.Queue'Class;
      Objects      : Memory_Object_List;
      Flags        : Migration_Flags := (others => False);
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event
   is
      function To_Bitfield (Value : Migration_Flags) return Bitfield is
        Result : Bitfield := 0;
      begin
         if Value.To_Host then
            Result := Result or 1;
         end if;
         if Value.Content_Undefined then
            Result := Result or 2;
         end if;
         return Result;
      end To_Bitfield;

      Raw_Objects : Address_List (Objects'Range);
      Ret_Event   : aliased System.Address;
      Error       : Enumerations.Error_Code;
   begin
      for Index in Objects'Range loop
         Raw_Objects (Index) := CL_Object (Objects (Index).all).Location;
      end loop;

      if Wait_For'Length = 0 then
         Error := API.Enqueue_Migrate_Mem_Objects
           (Queue       => CL_Object (Target_Queue).Location, 
            Num_Objects => UInt (Raw_Objects'Length),
            Objects     => Raw_Objects (Raw_Objects'First)'Address, 
            Flags       => To_Bitfield (Value => Flags),
            Wait_Count  => 0, 
            Wait_List   => System.Null_Address, 
            Event       => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Migrate_Mem_Objects
              (Queue       => CL_Object (Target_Queue).Location, 
               Num_Objects => UInt (Raw_Objects'Length),
               Objects     => Raw_Objects (Raw_Objects'First)'Address, 
               Flags       => To_Bitfield (Value => Flags),
               Wait_Count  => UInt (Raw_Wait'Length), 
               Wait_List   => Raw_Wait (Raw_Wait'First)'Address,
               Event       => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                           Location => Ret_Event);
   end Migrate_Memory_Objects;

   function Execute_Native_Kernel
     (Target_Queue  : Command_Queues.Queue'Class;
      Callback      : Native_Kernel_Callback;
      Arguments     : System.Address;
      Argument_Size : Size;
      Wait_For      : Events.Event_List := Events.No_Events)
      return Events.Event
   is
      function To_Raw_Callback is
        new Ada.Unchecked_Conversion
          (Native_Kernel_Callback, API.Native_Kernel_Raw);
      Ret_Event : aliased System.Address;
      Error     : Enumerations.Error_Code;
   begin
      if Callback = null then
         raise Constraint_Error with "native kernel callback must not be null";
      end if;

      if Wait_For'Length = 0 then
         Error := API.Enqueue_Native_Kernel
           (Queue            => CL_Object (Target_Queue).Location, 
            Callback         => To_Raw_Callback (Callback),
            Arguments        => Arguments, 
            Arguments_Size   => Argument_Size, 
            Num_Objects      => 0, 
            Objects          => System.Null_Address,
            Object_Locations => System.Null_Address, 
            Wait_Count       => 0, 
            Wait_List        => System.Null_Address,
            Event            => Ret_Event'Unchecked_Access);
      else
         declare
            Raw_Wait : Address_List := Raw_Event_List (Wait_For);
         begin
            Error := API.Enqueue_Native_Kernel
              (Queue            => CL_Object (Target_Queue).Location, 
               Callback         => To_Raw_Callback (Callback),
               Arguments        => Arguments, 
               Arguments_Size   => Argument_Size,
               Num_Objects      => 0, 
               Objects          => System.Null_Address,
               Object_Locations => System.Null_Address, 
               Wait_Count       => UInt (Raw_Wait'Length),
               Wait_List        => Raw_Wait (Raw_Wait'First)'Address,
               Event            => Ret_Event'Unchecked_Access);
         end;
      end if;
      Helpers.Error_Handler (Error);
      return Events.Event'(Ada.Finalization.Controlled with
                           Location => Ret_Event);
   end Execute_Native_Kernel;

end CL.Queueing;
