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

with CL.Command_Queues;
with CL.Events;
with CL.Kernels;
with CL.Memory;

private with CL.Helpers;

package CL.Queueing is
   subtype Kernel_Dimension is UInt range 1 .. 3;

   type Map_Flags_Reserved is mod 2 ** 61;

   type Map_Flags is record
      Read                    : Boolean := False;
      Write                   : Boolean := False;
      Write_Invalidate_Region : Boolean := False;
      Reserved                : Map_Flags_Reserved := 0;
   end record;

   type Migration_Flags is record
      To_Host           : Boolean := False;
      Content_Undefined : Boolean := False;
   end record;

   type Memory_Object_List is
     array (Positive range <>) of access constant Memory.Memory_Object'Class;

   type Native_Kernel_Callback is
     access procedure (Arguments : System.Address);
   pragma Convention (C, Native_Kernel_Callback);

   function Execute_Kernel (Target_Queue     : Command_Queues.Queue'Class;
                            Kernel           : Kernels.Kernel'Class;
                            Dimension        : Kernel_Dimension;
                            Global_Work_Size : access constant Size_List;
                            Local_Work_Size  : access constant Size_List;
                            Wait_For         : access Events.Event_List)
                            return Events.Event;

   function Execute_Task (Target_Queue : Command_Queues.Queue'Class;
                          Kernel       : Kernels.Kernel'Class;
                          Wait_For     : access Events.Event_List)
                          return Events.Event;

   function Marker
     (Target_Queue : Command_Queues.Queue'Class;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event;

   function Barrier
     (Target_Queue : Command_Queues.Queue'Class;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event;

   function Migrate_Memory_Objects
     (Target_Queue : Command_Queues.Queue'Class;
      Objects      : Memory_Object_List;
      Flags        : Migration_Flags := (others => False);
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event;

   function Execute_Native_Kernel
     (Target_Queue : Command_Queues.Queue'Class;
      Callback     : Native_Kernel_Callback;
      Arguments    : System.Address;
      Argument_Size : Size;
      Wait_For     : Events.Event_List := Events.No_Events)
      return Events.Event;

private
   for Map_Flags use record
      Read                    at 0 range 0 .. 0;
      Write                   at 0 range 1 .. 1;
      Write_Invalidate_Region at 0 range 2 .. 2;
      Reserved                at 0 range 3 .. 63;
   end record;
   for Map_Flags'Size use Bitfield'Size;
   pragma Convention (C_Pass_By_Copy, Map_Flags);

   for Migration_Flags use record
      To_Host           at 0 range 0 .. 0;
      Content_Undefined at 0 range 1 .. 1;
   end record;

   function Raw_Event_List is new Helpers.Raw_List_From_Polymorphic
     (Element_T => Events.Event, Element_List_T => Events.Event_List);
end CL.Queueing;
