with AUnit;
with AUnit.Assertions;

with CL;
with CL.Contexts;
with CL.Platforms;

package body CL_Test.Context_Cases is

   package Registration is new AUnit.Test_Cases.Specific_Test_Case_Registration
     (Test_Case);

   use type CL.Contexts.Context;
   use type CL.Platforms.Device;
   use type CL.Platforms.Platform;
   use type CL.UInt;

   Callback_Invocations : Natural := 0;

   procedure Error_Callback
     (Error_Info : String; Private_Info : CL.Char_List)
   is
      pragma Unreferenced (Error_Info, Private_Info);
   begin
      Callback_Invocations := Callback_Invocations + 1;
   end Error_Callback;

   function First_Platform return CL.Platforms.Platform is
      Platforms : constant CL.Platforms.Platform_List := CL.Platforms.List;
   begin
      AUnit.Assertions.Assert
        (Platforms'Length > 0, "No OpenCL platform was found");
      return Platforms (Platforms'First);
   end First_Platform;

   function All_Devices
     (Platform : CL.Platforms.Platform) return CL.Platforms.Device_List
   is
      Devices : constant CL.Platforms.Device_List :=
        Platform.Devices (CL.Platforms.Device_Kind_All);
   begin
      AUnit.Assertions.Assert
        (Devices'Length > 0, "The selected OpenCL platform has no devices");
      return Devices;
   end All_Devices;

   procedure Assert_Same_Devices
     (Expected : CL.Platforms.Device_List;
      Actual   : CL.Platforms.Device_List)
   is
   begin
      AUnit.Assertions.Assert
        (Actual'Length = Expected'Length,
         "The context returned an unexpected number of devices");

      for Offset in 0 .. Expected'Length - 1 loop
         AUnit.Assertions.Assert
           (Actual (Actual'First + Offset) =
              Expected (Expected'First + Offset),
            "The context returned an unexpected device at offset" &
              Offset'Image);
      end loop;
   end Assert_Same_Devices;

   procedure Test_Null_Context_Lifecycle
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);
      Context : CL.Contexts.Context;
   begin
      AUnit.Assertions.Assert
        (not Context.Initialized,
         "A default-initialized context should be uninitialized");

      CL.Contexts.Adjust (Context);
      AUnit.Assertions.Assert
        (not Context.Initialized,
         "Adjust initialized a null context");

      CL.Contexts.Finalize (Context);
      AUnit.Assertions.Assert
        (not Context.Initialized,
         "Finalize initialized a null context");
   end Test_Null_Context_Lifecycle;

   procedure Test_Explicit_Devices
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);

      Platform : constant CL.Platforms.Platform := First_Platform;
      Expected : constant CL.Platforms.Device_List := All_Devices (Platform);
      Context  : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_For_Devices
          (Platform => Platform,
           Devices  => Expected);
   begin
      AUnit.Assertions.Assert
        (Context.Initialized,
         "The explicit-device context was not initialized");
      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "A new explicit-device context should have reference count 1");
      AUnit.Assertions.Assert
        (Context.Platform = Platform,
         "The explicit-device context returned the wrong platform");
      Assert_Same_Devices (Expected, Context.Devices);

      declare
         Copy : constant CL.Contexts.Context := Context;
      begin
         AUnit.Assertions.Assert
           (Copy = Context, "A context copy refers to a different object");
         AUnit.Assertions.Assert
           (Context.Reference_Count = 2,
            "Copying a context should increment its reference count");
      end;

      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "Finalizing a copy should restore the context reference count");
   end Test_Explicit_Devices;

   procedure Test_Explicit_Devices_With_Properties
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);

      Platform : constant CL.Platforms.Platform := First_Platform;
      Devices  : constant CL.Platforms.Device_List := All_Devices (Platform);
      Context  : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_For_Devices
          (Platform          => Platform,
           Devices           => Devices (Devices'First .. Devices'First),
           Callback          => Error_Callback'Access,
           Interop_User_Sync => True);
      Actual : constant CL.Platforms.Device_List := Context.Devices;
   begin
      AUnit.Assertions.Assert
        (Context.Initialized,
         "The callback-enabled explicit-device context was not initialized");
      AUnit.Assertions.Assert
        (Context.Platform = Platform,
         "The callback-enabled context returned the wrong platform");
      AUnit.Assertions.Assert
        (Actual'Length = 1,
         "The callback-enabled context should contain one device");
      AUnit.Assertions.Assert
        (Actual (Actual'First) = Devices (Devices'First),
         "The callback-enabled context returned the wrong device");
   end Test_Explicit_Devices_With_Properties;

   procedure Test_From_Device_Type
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);

      Platform : constant CL.Platforms.Platform := First_Platform;
      Expected : constant CL.Platforms.Device_List := All_Devices (Platform);
      Context  : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_From_Type
          (Platform => Platform,
           Dev_Type => CL.Platforms.Device_Kind_All);
   begin
      AUnit.Assertions.Assert
        (Context.Initialized, "The device-type context was not initialized");
      AUnit.Assertions.Assert
        (Context.Reference_Count = 1,
         "A new device-type context should have reference count 1");
      AUnit.Assertions.Assert
        (Context.Platform = Platform,
         "The device-type context returned the wrong platform");
      Assert_Same_Devices (Expected, Context.Devices);
   end Test_From_Device_Type;

   procedure Test_From_Default_Device_Type
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);

      Platform    : constant CL.Platforms.Platform := First_Platform;
      Default_Kind : constant CL.Platforms.Device_Kind :=
        (Default => True, Reserved => [others => False], others => False);
      Context     : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_From_Type
          (Platform => Platform,
           Dev_Type => Default_Kind);
   begin
      AUnit.Assertions.Assert
        (Context.Initialized,
         "The default-device context was not initialized");
      AUnit.Assertions.Assert
        (Context.Platform = Platform,
         "The default-device context returned the wrong platform");
      AUnit.Assertions.Assert
        (Context.Devices'Length > 0,
         "The default-device context contains no devices");
   end Test_From_Default_Device_Type;

   procedure Test_From_Device_Type_With_Properties
     (Test : in out Test_Case'Class)
   is
      pragma Unreferenced (Test);

      Platform : constant CL.Platforms.Platform := First_Platform;
      Context  : constant CL.Contexts.Context :=
        CL.Contexts.Constructors.Create_From_Type
          (Platform          => Platform,
           Dev_Type          => CL.Platforms.Device_Kind_All,
           Callback          => Error_Callback'Access,
           Interop_User_Sync => True);
   begin
      AUnit.Assertions.Assert
        (Context.Initialized,
         "The callback-enabled device-type context was not initialized");
      AUnit.Assertions.Assert
        (Context.Platform = Platform,
         "The callback-enabled device-type context returned the wrong " &
           "platform");
      AUnit.Assertions.Assert
        (Context.Devices'Length > 0,
         "The callback-enabled device-type context contains no devices");
   end Test_From_Device_Type_With_Properties;

   overriding function Name
     (Test : Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (Test);
   begin
      return AUnit.Format ("CL.Contexts API");
   end Name;

   overriding procedure Register_Tests (Test : in out Test_Case) is
   begin
      Registration.Register_Wrapper
        (Test, Test_Null_Context_Lifecycle'Access, "null context lifecycle");
      Registration.Register_Wrapper
        (Test, Test_Explicit_Devices'Access, "explicit devices");
      Registration.Register_Wrapper
        (Test, Test_Explicit_Devices_With_Properties'Access,
         "explicit devices with callback and interop property");
      Registration.Register_Wrapper
        (Test, Test_From_Device_Type'Access, "device type");
      Registration.Register_Wrapper
        (Test, Test_From_Default_Device_Type'Access, "default device type");
      Registration.Register_Wrapper
        (Test, Test_From_Device_Type_With_Properties'Access,
         "device type with callback and interop property");
   end Register_Tests;

end CL_Test.Context_Cases;