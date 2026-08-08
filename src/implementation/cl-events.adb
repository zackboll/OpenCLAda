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
with CL.Helpers;

package body CL.Events is

   function Callback_To_Address is
     new Ada.Unchecked_Conversion (Event_Callback, System.Address);
   function Address_To_Callback is
     new Ada.Unchecked_Conversion (System.Address, Event_Callback);

   procedure Callback_Dispatcher
     (Raw_Event : System.Address;
      Event_Status : Int;
      User_Data : System.Address);
   pragma Convention (C, Callback_Dispatcher);

   procedure Callback_Dispatcher
     (Raw_Event : System.Address;
      Event_Status : Int;
      User_Data : System.Address)
   is
      Callback : constant Event_Callback := Address_To_Callback (User_Data);
   begin
      if Callback /= null then
         Helpers.Error_Handler (API.Retain_Event (Raw_Event));
         Callback
           (Subject => Event'(Ada.Finalization.Controlled with Location => Raw_Event),
            Status => Event_Status);
      end if;
   end Callback_Dispatcher;

   package body Constructors is
      function Create_User_Event
        (Context : Contexts.Context'Class) return Event
      is
         Error     : aliased Enumerations.Error_Code;
         Raw_Event : System.Address;
      begin
         Raw_Event := API.Create_User_Event
           (Context => CL_Object (Context).Location, Error => Error'Unchecked_Access);
         Helpers.Error_Handler (Error);
         return Event'(Ada.Finalization.Controlled with Location => Raw_Event);
      end Create_User_Event;
   end Constructors;

   procedure Adjust (Object : in out Event) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Retain_Event (Object.Location));
      end if;
   end Adjust;

   procedure Finalize (Object : in out Event) is
      use type System.Address;
   begin
      if Object.Location /= System.Null_Address then
         Helpers.Error_Handler (API.Release_Event (Object.Location));
      end if;
   end Finalize;

   procedure Wait_For (Subject : Event) is
      List : constant Event_List (1..1) := [1 => Subject'Unchecked_Access];
   begin
      Wait_For (List);
   end Wait_For;

   procedure Wait_For (Subjects : Event_List) is
      Raw_List : Address_List (Subjects'Range);
   begin
      if Subjects'Length = 0 then
         return;
      end if;

      for Index in Subjects'Range loop
         if Subjects (Index) = null then
            raise CL.Invalid_Event;
         end if;
         Raw_List (Index) := Subjects (Index).Location;
      end loop;
      Helpers.Error_Handler
        (API.Wait_For_Events
           (Num_Events => UInt (Subjects'Length), 
            Event_List => Raw_List (Raw_List'First)'Address));
   end Wait_For;

   function Command_Queue (Source : Event) return Command_Queues.Queue is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
      function New_CQ_Reference is
         new Helpers.New_Reference (Object_T => Command_Queues.Queue);
   begin
      return New_CQ_Reference (Getter (Source, Enumerations.Command_Queue));
   end Command_Queue;

   function Kind (Source : Event) return Command_Type is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Command_Type,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
   begin
      return Getter (Source, Enumerations.Command_T);
   end Kind;

   function Reference_Count (Source : Event) return UInt is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => UInt,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
   begin
      return Getter (Source, Enumerations.Reference_Count);
   end Reference_Count;

   function Status (Source : Event) return Execution_Status is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Execution_Status,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
   begin
      return Getter (Source, Enumerations.Command_Execution_Status);
   end Status;

   function Status_Code (Source : Event) return Int is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => Int,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
   begin
      return Getter (Source, Enumerations.Command_Execution_Status);
   end Status_Code;

   function Context (Source : Event) return Contexts.Context is
      function Getter is
        new Helpers.Get_Parameter (Return_T    => System.Address,
                                   Parameter_T => Enumerations.Event_Info,
                                   C_Getter    => API.Get_Event_Info);
      function New_Context_Reference is
        new Helpers.New_Reference (Contexts.Context);
   begin
      return New_Context_Reference (Getter (Source, Enumerations.Context));
   end Context;

   procedure Set_User_Event_Complete (Source : Event) is
   begin
      Helpers.Error_Handler
        (API.Set_User_Event_Status (Target           => Source.Location, 
                                    Execution_Status => 0));
   end Set_User_Event_Complete;

   procedure Set_User_Event_Error (Source : Event; Error_Status : Int) is
   begin
      Helpers.Error_Handler
        (Error => API.Set_User_Event_Status (Target           => Source.Location, 
                                             Execution_Status => Error_Status));
   end Set_User_Event_Error;

   procedure Set_Callback
     (Source   : Event;
      Trigger  : Execution_Status;
      Callback : Event_Callback)
   is
   begin
      if Callback = null then
         raise Constraint_Error with "event callback must not be null";
      end if;
      Helpers.Error_Handler
        (Error => API.Set_Event_Callback
           (Target        => Source.Location, 
            Callback_Type => Int (Execution_Status'Enum_Rep (Trigger)),
            Callback      => Callback_Dispatcher'Access, 
            User_Data     => Callback_To_Address (Callback)));
   end Set_Callback;

   function Profiling_Info_ULong is
     new Helpers.Get_Parameter (Return_T    => ULong,
                                Parameter_T => Enumerations.Profiling_Info,
                                C_Getter    => API.Get_Event_Profiling_Info);

   function Queued_At (Source : Event) return ULong is
   begin
      return Profiling_Info_ULong (Source, Enumerations.Command_Queued);
   end Queued_At;

   function Submitted_At (Source : Event) return ULong is
   begin
      return Profiling_Info_ULong (Source, Enumerations.Submit);
   end Submitted_At;

   function Started_At (Source : Event) return ULong is
   begin
      return Profiling_Info_ULong (Source, Enumerations.Start);
   end Started_At;

   function Ended_At (Source : Event) return ULong is
   begin
      return Profiling_Info_ULong (Source, Enumerations.P_End);
   end Ended_At;
end CL.Events;
