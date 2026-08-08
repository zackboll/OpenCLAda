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

with Interfaces.C;
with Interfaces.C.Strings;

with CL.Enumerations;
with CL.Contexts;
with CL.Memory;
with CL.Memory.Images;
with CL.Samplers;
with CL.Programs;
with CL.Queueing;

private package CL.API is

   type Image_Format_Ptr is access all CL.Memory.Images.Image_Format;
   pragma Convention (C, Image_Format_Ptr);

   -----------------------------------------------------------------------------
   --  Platform APIs
   -----------------------------------------------------------------------------

   function Get_Platform_IDs (Num_Entries   : CL.UInt;
                              Value : System.Address;
                              Num_Platforms : CL.UInt_Ptr)
                              return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Platform_IDs,
                  External_Name => "clGetPlatformIDs");

   function Get_Platform_Info (Source      : System.Address;
                               Info        : Enumerations.Platform_Info;
                               Value_Size  : Size;
                               Value       : access Interfaces.C.char_array;
                               Return_Size : Size_Ptr)
                               return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Platform_Info,
                  External_Name => "clGetPlatformInfo");

   -----------------------------------------------------------------------------
   --  Device APIs
   -----------------------------------------------------------------------------

   function Get_Device_IDs (Source      : System.Address;
                            Types       : Bitfield;
                            Num_Entries : UInt;
                            Value       : System.Address;
                            Num_Devices : UInt_Ptr)
                            return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Device_IDs,
                  External_Name => "clGetDeviceIDs");

   function Get_Device_Info (Source      : System.Address;
                             Param       : Enumerations.Device_Info;
                             Num_Entries : Size;
                             Value       : access Interfaces.C.char_array;
                             Return_Size : Size_Ptr)
                             return Enumerations.Error_Code;
   function Get_Device_Info (Source      : System.Address;
                             Param       : Enumerations.Device_Info;
                             Num_Entries : Size;
                             Value       : System.Address;
                             Return_Size : Size_Ptr)
                             return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Device_Info,
                  External_Name => "clGetDeviceInfo");

   function Create_Sub_Devices
     (Device          : System.Address;
      Properties      : System.Address;
      Num_Devices     : UInt;
      Devices         : System.Address;
      Num_Devices_Ret : UInt_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Create_Sub_Devices,
                  External_Name => "clCreateSubDevices");

   function Retain_Device (Device : System.Address)
                           return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Device,
                  External_Name => "clRetainDevice");

   function Release_Device (Device : System.Address)
                            return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Device,
                  External_Name => "clReleaseDevice");

   -----------------------------------------------------------------------------
   --  Context APIs
   -----------------------------------------------------------------------------
   type Error_Callback is access procedure (Error_Info   : IFC.Strings.chars_ptr;
                                            Private_Info : C_Chars.Pointer;
                                            CB           : IFC.ptrdiff_t;
                                            User_Data    : CL.Contexts.Error_Callback);
   pragma Convention (C, Error_Callback);

   function Create_Context (Properties  : Address_Ptr;
                            Num_Devices : UInt;
                            Devices     : System.Address;
                            Callback    : Error_Callback;
                            User_Data   : System.Address;
                            Error       : Enumerations.Error_Ptr)
                            return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Context,
                  External_Name => "clCreateContext");

   function Create_Context_From_Type (Properties : Address_Ptr;
                                      Dev_Type   : Bitfield;
                                      Callback   : Error_Callback;
                                      User_Data  : System.Address;
                                      Error      : Enumerations.Error_Ptr)
                                      return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Context_From_Type,
                  External_Name => "clCreateContextFromType");

   function Retain_Context (Target : System.Address)
                            return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Context,
                  External_Name => "clRetainContext");

   function Release_Context (Target : System.Address)
                             return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Context,
                  External_Name => "clReleaseContext");

   function Get_Context_Info (Source      : System.Address;
                              Param       : Enumerations.Context_Info;
                              Value_Size  : Size;
                              Value       : System.Address;
                              Return_Size : Size_Ptr)
                              return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Context_Info,
                  External_Name => "clGetContextInfo");

   -----------------------------------------------------------------------------
   --  Command Queue APIs
   -----------------------------------------------------------------------------

   function Create_Command_Queue (Attach_To  : System.Address;
                                  Device     : System.Address;
                                  Properties : Bitfield;
                                  Error      : Enumerations.Error_Ptr)
                                  return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Command_Queue,
                  External_Name => "clCreateCommandQueue");

   function Retain_Command_Queue (Queue : System.Address)
                                   return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Command_Queue,
                  External_Name => "clRetainCommandQueue");


   function Release_Command_Queue (Queue : System.Address)
                                   return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Command_Queue,
                  External_Name => "clReleaseCommandQueue");

   function Get_Command_Queue_Info (Queue      : System.Address;
                                    Param      : Enumerations.Command_Queue_Info;
                                    Value_Size : Size;
                                    Value      : System.Address;
                                    Return_Size : Size_Ptr)
                                    return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Command_Queue_Info,
                  External_Name => "clGetCommandQueueInfo");

   -----------------------------------------------------------------------------
   --  Memory APIs
   -----------------------------------------------------------------------------

   function Create_Buffer (Context  : System.Address;
                           Flags    : Bitfield;
                           Size     : CL.Size;
                           Host_Ptr : System.Address;
                           Error    : Enumerations.Error_Ptr)
                           return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Buffer,
                  External_Name => "clCreateBuffer");

   function Create_Image2D (Context   : System.Address;
                            Flags     : Bitfield;
                            Format    : Image_Format_Ptr;
                            Width     : Size;
                            Height    : Size;
                            Row_Pitch : Size;
                            Host_Ptr  : System.Address;
                            Error     : Enumerations.Error_Ptr)
                            return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Image2D,
                  External_Name => "clCreateImage2D");

   function Create_Image3D (Context     : System.Address;
                            Flags       : Bitfield;
                            Format      : Image_Format_Ptr;
                            Width       : Size;
                            Height      : Size;
                            Depth       : Size;
                            Row_Pitch   : Size;
                            Slice_Pitch : Size;
                            Host_Ptr    : System.Address;
                            Error       : Enumerations.Error_Ptr)
                            return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Image3D,
                  External_Name => "clCreateImage3D");

   function Get_Mem_Object_Info (Object      : System.Address;
                                 Info        : Enumerations.Memory_Info;
                                 Size        : CL.Size;
                                 Value       : System.Address;
                                 Return_Size : Size_Ptr)
                                 return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Mem_Object_Info,
                  External_Name => "clGetMemObjectInfo");

   function Create_Sub_Buffer
     (Source      : System.Address;
      Flags       : Bitfield;
      Create_Type : Enumerations.Buffer_Create_Type;
      Info        : System.Address;
      Error       : Enumerations.Error_Ptr) return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Sub_Buffer,
                  External_Name => "clCreateSubBuffer");

   function Create_Image
     (Context  : System.Address;
      Flags    : Bitfield;
      Format   : System.Address;
      Desc     : System.Address;
      Host_Ptr : System.Address;
      Error    : Enumerations.Error_Ptr) return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Image,
                  External_Name => "clCreateImage");

   function Retain_Mem_Object (Mem_Object : System.Address)
                               return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Mem_Object,
                  External_Name => "clRetainMemObject");

   function Release_Mem_Object (Mem_Object : System.Address)
                                return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Mem_Object,
                  External_Name => "clReleaseMemObject");

   function Get_Supported_Image_Formats (Context     : System.Address;
                                         Flags       : Bitfield;
                                         Object_Type : CL.Memory.Images.Image_Type;
                                         Num_Entries : UInt;
                                         Value       : System.Address;
                                         Return_Size : UInt_Ptr)
                                         return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Supported_Image_Formats,
                  External_Name => "clGetSupportedImageFormats");

   function Get_Image_Info (Object      : System.Address;
                            Info        : Enumerations.Image_Info;
                            Size        : CL.Size;
                            Value       : System.Address;
                            Return_Size : Size_Ptr)
                            return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Image_Info,
                  External_Name => "clGetImageInfo");

   type Destructor_Callback_Raw is
     access procedure (Object : System.Address; User_Data : System.Address);
   pragma Convention (C, Destructor_Callback_Raw);

   function Set_Mem_Object_Destructor_Callback
     (Object    : System.Address;
      Callback  : Destructor_Callback_Raw;
      User_Data : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall,
                  Entity => Set_Mem_Object_Destructor_Callback,
                  External_Name => "clSetMemObjectDestructorCallback");

   -----------------------------------------------------------------------------
   --  Sampler APIs
   -----------------------------------------------------------------------------

   function Create_Sampler (Context           : System.Address;
                            Normalized_Coords : Bool;
                            Addressing        : Samplers.Addressing_Mode;
                            Filter            : Samplers.Filter_Mode;
                            Error             : Enumerations.Error_Ptr)
                            return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Sampler,
                  External_Name => "clCreateSampler");

   function Retain_Sampler (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Sampler,
                  External_Name => "clRetainSampler");

   function Release_Sampler (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Sampler,
                  External_Name => "clReleaseSampler");

   function Get_Sampler_Info (Source      : System.Address;
                              Info        : Enumerations.Sampler_Info;
                              Value_Size  : Size;
                              Value       : System.Address;
                              Return_Size : Size_Ptr)
                              return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Sampler_Info,
                  External_Name => "clGetSamplerInfo");

   -----------------------------------------------------------------------------
   --  Program APIs
   -----------------------------------------------------------------------------

   function Create_Program_With_Source (Context : System.Address;
                                        Count   : UInt;
                                        Sources : access IFC.Strings.chars_ptr;
                                        Lengths : access Size;
                                        Error   : Enumerations.Error_Ptr)
                                        return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Program_With_Source,
                  External_Name => "clCreateProgramWithSource");

   function Create_Program_With_Binary (Context     : System.Address;
                                        Num_Devices : UInt;
                                        Devices     : System.Address;
                                        Lengths     : Size_Ptr;
                                        Binaries    : access System.Address;
                                        Status      : access Int;
                                        Error       : Enumerations.Error_Ptr)
                                        return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Program_With_Binary,
                  External_Name => "clCreateProgramWithBinary");

   function Create_Program_With_Built_In_Kernels
     (Context      : System.Address;
      Num_Devices  : UInt;
      Devices      : System.Address;
      Kernel_Names : Interfaces.C.Strings.chars_ptr;
      Error        : Enumerations.Error_Ptr) return System.Address;
   pragma Import
     (Convention => StdCall, Entity => Create_Program_With_Built_In_Kernels,
      External_Name => "clCreateProgramWithBuiltInKernels");

   function Retain_Program (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Program,
                  External_Name => "clRetainProgram");

   function Release_Program (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Program,
                  External_Name => "clReleaseProgram");

   type Build_Callback_Raw is
     access procedure (Subject : System.Address; Callback : Programs.Build_Callback);
   pragma Convention (C, Build_Callback_Raw);

   function Build_Program (Target      : System.Address;
                           Num_Devices : UInt;
                           Device_List : System.Address;
                           Options     : IFC.Strings.chars_ptr;
                           Callback    : Build_Callback_Raw;
                           User_Data   : Programs.Build_Callback)
                           return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Build_Program,
                  External_Name => "clBuildProgram");

   function Compile_Program
     (Target               : System.Address;
      Num_Devices          : UInt;
      Devices              : System.Address;
      Options              : Interfaces.C.Strings.chars_ptr;
      Num_Input_Headers    : UInt;
      Input_Headers        : System.Address;
      Header_Include_Names : System.Address;
      Callback             : Build_Callback_Raw;
      User_Data            : CL.Programs.Build_Callback)
      return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Compile_Program,
                  External_Name => "clCompileProgram");

   function Link_Program
     (Context            : System.Address;
      Num_Devices        : UInt;
      Devices            : System.Address;
      Options            : Interfaces.C.Strings.chars_ptr;
      Num_Input_Programs : UInt;
      Input_Programs     : System.Address;
      Callback           : Build_Callback_Raw;
      User_Data          : CL.Programs.Build_Callback;
      Error              : Enumerations.Error_Ptr) return System.Address;
   pragma Import (Convention => StdCall, Entity => Link_Program,
                  External_Name => "clLinkProgram");

   function Unload_Platform_Compiler (Platform : System.Address)
                                      return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Unload_Platform_Compiler,
                  External_Name => "clUnloadPlatformCompiler");

   function Unload_Compiler return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Unload_Compiler,
                  External_Name => "clUnloadCompiler");

   function Get_Program_Info (Source      : System.Address;
                              Param       : Enumerations.Program_Info;
                              Value_Size  : Size;
                              Value       : System.Address;
                              Return_Size : Size_Ptr)
                              return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Program_Info,
                  External_Name => "clGetProgramInfo");

   function Get_Program_Build_Info (Source      : System.Address;
                                    Device      : System.Address;
                                    Param       : Enumerations.Program_Build_Info;
                                    Value_Size  : Size;
                                    Value       : System.Address;
                                    Return_Size : Size_Ptr)
                                    return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Program_Build_Info,
                  External_Name => "clGetProgramBuildInfo");

   -----------------------------------------------------------------------------
   --  Kernel APIs
   -----------------------------------------------------------------------------

   function Create_Kernel (Source : System.Address;
                           Name   : IFC.Strings.chars_ptr;
                           Error  : Enumerations.Error_Ptr) return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_Kernel,
                  External_Name => "clCreateKernel");

   function Create_Kernels_In_Program (Source      : System.Address;
                                       Num_Kernels : UInt;
                                       Kernels     : System.Address;
                                       Return_Size : UInt_Ptr)
                                       return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Create_Kernels_In_Program,
                  External_Name => "clCreateKernelsInProgram");

   function Retain_Kernel (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Kernel,
                  External_Name => "clRetainKernel");

   function Release_Kernel (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Kernel,
                  External_Name => "clReleaseKernel");

   function Set_Kernel_Arg (Target     : System.Address;
                            Arg_Index  : UInt;
                            Value_Size : Size;
                            Value      : System.Address)
                            return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Set_Kernel_Arg,
                  External_Name => "clSetKernelArg");

   function Get_Kernel_Info (Source      : System.Address;
                             Param       : Enumerations.Kernel_Info;
                             Value_Size  : Size;
                             Value       : System.Address;
                             Return_Size : Size_Ptr)
                             return Enumerations.Error_Code;
   function Get_Kernel_Info (Source      : System.Address;
                             Param       : Enumerations.Kernel_Info;
                             Value_Size  : Size;
                             Value       : access Interfaces.C.char_array;
                             Return_Size : Size_Ptr)
                             return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Kernel_Info,
                  External_Name => "clGetKernelInfo");

   function Get_Kernel_Arg_Info
     (Source      : System.Address;
      Arg_Index   : UInt;
      Param       : Enumerations.Kernel_Arg_Info;
      Value_Size  : Size;
      Value       : System.Address;
      Return_Size : Size_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Kernel_Arg_Info,
                  External_Name => "clGetKernelArgInfo");

   function Get_Kernel_Work_Group_Info (Source      : System.Address;
                                        Device      : System.Address;
                                        Param       : Enumerations.Kernel_Work_Group_Info;
                                        Value_Size  : Size;
                                        Value       : System.Address;
                                        Return_Size : Size_Ptr)
                                        return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Kernel_Work_Group_Info,
                  External_Name => "clGetKernelWorkGroupInfo");

   -----------------------------------------------------------------------------
   --  Event APIs
   -----------------------------------------------------------------------------

   function Wait_For_Events (Num_Events : CL.UInt;
                             Event_List : System.Address)
                             return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Wait_For_Events,
                  External_Name => "clWaitForEvents");

   function Get_Event_Info (Source      : System.Address;
                            Param       : Enumerations.Event_Info;
                            Value_Size  : Size;
                            Value       : System.Address;
                            Return_Size : Size_Ptr)
                            return Enumerations.Error_Code;

   function Create_User_Event (Context : System.Address;
                               Error   : Enumerations.Error_Ptr)
                               return System.Address;
   pragma Import (Convention => StdCall, Entity => Create_User_Event,
                  External_Name => "clCreateUserEvent");
   pragma Import (Convention => StdCall, Entity => Get_Event_Info,
                  External_Name => "clGetEventInfo");

   function Retain_Event (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Retain_Event,
                  External_Name => "clRetainEvent");

   function Release_Event (Target : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Release_Event,
                  External_Name => "clReleaseEvent");

   function Set_User_Event_Status
     (Target : System.Address; Execution_Status : Int)
      return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Set_User_Event_Status,
                  External_Name => "clSetUserEventStatus");

   type Event_Callback_Raw is
     access procedure (Event       : System.Address;
                       Event_Status : Int;
                       User_Data    : System.Address);
   pragma Convention (C, Event_Callback_Raw);

   function Set_Event_Callback
     (Target        : System.Address;
      Callback_Type : Int;
      Callback      : Event_Callback_Raw;
      User_Data     : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Set_Event_Callback,
                  External_Name => "clSetEventCallback");

   function Get_Event_Profiling_Info (Source      : System.Address;
                                      Param       : Enumerations.Profiling_Info;
                                      Value_Size  : Size;
                                      Value       : System.Address;
                                      Return_Size : Size_Ptr)
                                      return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Get_Event_Profiling_Info,
                  External_Name => "clGetEventProfilingInfo");

   -----------------------------------------------------------------------------
   --  Flush & Finish APIs
   -----------------------------------------------------------------------------

   function Flush (Queue : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Flush,
                  External_Name => "clFlush");

   function Finish (Queue : System.Address) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Finish,
                  External_Name => "clFinish");

   -----------------------------------------------------------------------------
   --  Enqueued Commands APIs
   -----------------------------------------------------------------------------

   function Enqueue_Read_Buffer (Queue      : System.Address;
                                 Buffer     : System.Address;
                                 Blocking   : Bool;
                                 Offset     : Size;
                                 CB         : Size;
                                 Ptr        : System.Address;
                                 Num_Events : UInt;
                                 Event_List : Address_Ptr;
                                 Event      : Address_Ptr)
                                 return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Read_Buffer,
                  External_Name => "clEnqueueReadBuffer");

   function Enqueue_Read_Buffer_Rect
     (Queue              : System.Address;
      Buffer             : System.Address;
      Blocking           : Bool;
      Buffer_Origin      : System.Address;
      Host_Origin        : System.Address;
      Region             : System.Address;
      Buffer_Row_Pitch   : Size;
      Buffer_Slice_Pitch : Size;
      Host_Row_Pitch     : Size;
      Host_Slice_Pitch   : Size;
      Destination        : System.Address;
      Wait_Count         : UInt;
      Wait_List          : System.Address;
      Event              : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Read_Buffer_Rect,
                  External_Name => "clEnqueueReadBufferRect");

   function Enqueue_Write_Buffer (Queue      : System.Address;
                                  Buffer     : System.Address;
                                  Blocking   : Bool;
                                  Offset     : Size;
                                  Byte_Count : Size;
                                  Source     : System.Address;
                                  Wait_Count : UInt;
                                  Wait_List  : Address_Ptr;
                                  Event      : Address_Ptr)
                                  return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Write_Buffer,
                  External_Name => "clEnqueueWriteBuffer");

   function Enqueue_Write_Buffer_Rect
     (Queue              : System.Address;
      Buffer             : System.Address;
      Blocking           : Bool;
      Buffer_Origin      : System.Address;
      Host_Origin        : System.Address;
      Region             : System.Address;
      Buffer_Row_Pitch   : Size;
      Buffer_Slice_Pitch : Size;
      Host_Row_Pitch     : Size;
      Host_Slice_Pitch   : Size;
      Source             : System.Address;
      Wait_Count         : UInt;
      Wait_List          : System.Address;
      Event              : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Write_Buffer_Rect,
                  External_Name => "clEnqueueWriteBufferRect");

   function Enqueue_Fill_Buffer
     (Queue        : System.Address;
      Buffer       : System.Address;
      Pattern      : System.Address;
      Pattern_Size : Size;
      Offset       : Size;
      Byte_Count   : Size;
      Wait_Count   : UInt;
      Wait_List    : System.Address;
      Event        : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Fill_Buffer,
                  External_Name => "clEnqueueFillBuffer");

   function Enqueue_Copy_Buffer (Queue       : System.Address;
                                 Source      : System.Address;
                                 Destination : System.Address;
                                 Src_Offset  : Size;
                                 Dst_Offset  : Size;
                                 Byte_Count  : Size;
                                 Wait_Count  : UInt;
                                 Wait_List   : Address_Ptr;
                                 Event       : Address_Ptr)
                                 return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Copy_Buffer,
                  External_Name => "clEnqueueCopyBuffer");

   function Enqueue_Copy_Buffer_Rect
     (Queue           : System.Address;
      Source          : System.Address;
      Destination     : System.Address;
      Source_Origin   : System.Address;
      Dest_Origin     : System.Address;
      Region          : System.Address;
      Source_Row_Pitch   : Size;
      Source_Slice_Pitch : Size;
      Dest_Row_Pitch     : Size;
      Dest_Slice_Pitch   : Size;
      Wait_Count      : UInt;
      Wait_List       : System.Address;
      Event           : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Copy_Buffer_Rect,
                  External_Name => "clEnqueueCopyBufferRect");

   function Enqueue_Read_Image (Queue       : System.Address;
                                Image       : System.Address;
                                Blocking    : Bool;
                                Origin      : access constant Size;
                                Region      : access constant Size;
                                Row_Pitch   : Size;
                                Slice_Pitch : Size;
                                Ptr         : System.Address;
                                Num_Events  : UInt;
                                Event_List  : Address_Ptr;
                                Event       : Address_Ptr)
                                return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Read_Image,
                  External_Name => "clEnqueueReadImage");

   function Enqueue_Write_Image (Queue       : System.Address;
                                 Image       : System.Address;
                                 Blocking    : Bool;
                                 Origin      : access constant Size;
                                 Region      : access constant Size;
                                 Row_Pitch   : Size;
                                 Slice_Pitch : Size;
                                 Ptr         : System.Address;
                                 Num_Events  : UInt;
                                 Event_List  : Address_Ptr;
                                 Event       : Address_Ptr)
                                 return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Write_Image,
                  External_Name => "clEnqueueWriteImage");

   function Enqueue_Fill_Image
     (Queue      : System.Address;
      Image      : System.Address;
      Fill_Color : System.Address;
      Origin     : System.Address;
      Region     : System.Address;
      Wait_Count : UInt;
      Wait_List  : System.Address;
      Event      : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Fill_Image,
                  External_Name => "clEnqueueFillImage");

   function Enqueue_Copy_Image (Queue       : System.Address;
                                Source      : System.Address;
                                Dest        : System.Address;
                                Src_Origin  : access constant Size;
                                Dest_Origin : access constant Size;
                                Region      : access constant Size;
                                Num_Events  : UInt;
                                Event_List  : Address_Ptr;
                                Event       : Address_Ptr)
                                return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Copy_Image,
                  External_Name => "clEnqueueCopyImage");

   function Enqueue_Copy_Image_To_Buffer (Queue       : System.Address;
                                          Image       : System.Address;
                                          Buffer      : System.Address;
                                          Origin      : access constant Size;
                                          Region      : access constant Size;
                                          Dest_Offset : Size;
                                          Num_Events  : UInt;
                                          Event_List  : Address_Ptr;
                                          Event       : Address_Ptr)
                                          return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Copy_Image_To_Buffer,
                  External_Name => "clEnqueueCopyImageToBuffer");

   function Enqueue_Copy_Buffer_To_Image (Queue       : System.Address;
                                          Buffer      : System.Address;
                                          Image       : System.Address;
                                          Src_Offset  : Size;
                                          Origin      : access constant Size;
                                          Region      : access constant Size;
                                          Num_Events  : UInt;
                                          Event_List  : Address_Ptr;
                                          Event       : Address_Ptr)
                                          return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Copy_Buffer_To_Image,
                  External_Name => "clEnqueueCopyBufferToImage");

   function Enqueue_Map_Buffer (Queue      : System.Address;
                                Buffer     : System.Address;
                                Blocking   : Bool;
                                Map_Flags  : Queueing.Map_Flags;
                                Offset     : Size;
                                CB         : Size;
                                Num_Events : UInt;
                                Event_List : Address_Ptr;
                                Event      : Address_Ptr;
                                Error      : Enumerations.Error_Ptr)
                                return System.Address;
   pragma Import (Convention => StdCall, Entity => Enqueue_Map_Buffer,
                  External_Name => "clEnqueueMapBuffer");

   function Enqueue_Map_Image (Queue       : System.Address;
                               Image       : System.Address;
                               Blocking    : Bool;
                               Map_Flags   : Queueing.Map_Flags;
                               Origin      : access constant Size;
                               Region      : access constant Size;
                               Row_Pitch   : Size_Ptr;
                               Slice_Pitch : Size_Ptr;
                               Num_Events  : UInt;
                               Event_List  : Address_Ptr;
                               Event       : Address_Ptr;
                               Error       : Enumerations.Error_Ptr)
                               return System.Address;
   pragma Import (Convention => StdCall, Entity => Enqueue_Map_Image,
                  External_Name => "clEnqueueMapImage");

   function Enqueue_Unmap_Mem_Object (Queue      : System.Address;
                                      Memobj     : System.Address;
                                      Ptr        : System.Address;
                                      Num_Events : UInt;
                                      Event_List : Address_Ptr;
                                      Event      : Address_Ptr)
                                      return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Unmap_Mem_Object,
                  External_Name => "clEnqueueUnmapMemObject");

   function Enqueue_Migrate_Mem_Objects
     (Queue       : System.Address;
      Num_Objects : UInt;
      Objects     : System.Address;
      Flags       : Bitfield;
      Wait_Count  : UInt;
      Wait_List   : System.Address;
      Event       : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall,
                  Entity => Enqueue_Migrate_Mem_Objects,
                  External_Name => "clEnqueueMigrateMemObjects");

   type Native_Kernel_Raw is access procedure (Arguments : System.Address);
   pragma Convention (C, Native_Kernel_Raw);

   function Enqueue_Native_Kernel
     (Queue          : System.Address;
      Callback       : Native_Kernel_Raw;
      Arguments      : System.Address;
      Arguments_Size : Size;
      Num_Objects    : UInt;
      Objects        : System.Address;
      Object_Locations : System.Address;
      Wait_Count     : UInt;
      Wait_List      : System.Address;
      Event          : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Native_Kernel,
                  External_Name => "clEnqueueNativeKernel");

   function Enqueue_NDRange_Kernel (Queue              : System.Address;
                                    Kernel             : System.Address;
                                    Work_Dim           : UInt;
                                    Global_Work_Offset : access constant Size;
                                    Global_Work_Size   : access constant Size;
                                    Local_Work_Size    : access constant Size;
                                    Num_Events         : UInt;
                                    Event_List         : Address_Ptr;
                                    Event              : Address_Ptr)
                                    return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_NDRange_Kernel,
                  External_Name => "clEnqueueNDRangeKernel");

   function Enqueue_Task (Queue      : System.Address;
                          Kernel     : System.Address;
                          Num_Events : UInt;
                          Event_List : Address_Ptr;
                          Event      : Address_Ptr)
                          return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Task,
                  External_Name => "clEnqueueTask");

   -- Enqueue_Native_Kernel ommited

   function Enqueue_Marker_With_Wait_List
     (Queue      : System.Address;
      Wait_Count : UInt;
      Wait_List  : System.Address;
      Event      : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall,
                  Entity => Enqueue_Marker_With_Wait_List,
                  External_Name => "clEnqueueMarkerWithWaitList");

   function Enqueue_Barrier_With_Wait_List
     (Queue      : System.Address;
      Wait_Count : UInt;
      Wait_List  : System.Address;
      Event      : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall,
                  Entity => Enqueue_Barrier_With_Wait_List,
                  External_Name => "clEnqueueBarrierWithWaitList");

   function Get_Extension_Function_Address_For_Platform
     (Platform : System.Address;
      Name     : Interfaces.C.Strings.chars_ptr) return System.Address;
   pragma Import
     (Convention => StdCall,
      Entity => Get_Extension_Function_Address_For_Platform,
      External_Name => "clGetExtensionFunctionAddressForPlatform");

   function Enqueue_Marker (Queue : System.Address;
                            Event : Address_Ptr) return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Marker,
                  External_Name => "clEnqueueMarker");

   function Enqueue_Wait_For_Events (Queue      : System.Address;
                                     Num_Events : UInt;
                                     Event_List : Address_Ptr)
                                     return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Wait_For_Events,
                  External_Name => "clEnqueueWaitForEvents");

   function Enqueue_Barrier (Queue : System.Address)
                             return Enumerations.Error_Code;
   pragma Import (Convention => StdCall, Entity => Enqueue_Barrier,
                  External_Name => "clEnqueueBarrier");

   --  clGetExtensionFunctionAddress ommited

end CL.API;
