with AUnit;

with CL_Test.Context;
with CL_Test.Device;
with CL_Test.Hello_World;
with CL_Test.Memory;
with CL_Test.Platform;
with CL_Test.Vector_Passing;
with CL_Test.Vectors;

package body CL_Test.Legacy_Drivers is

   package Registration is new AUnit.Test_Cases.Specific_Test_Case_Registration
     (Test_Case);

   overriding function Name
     (Test : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (Test);
   begin
      return AUnit.Format ("Legacy OpenCL drivers");
   end Name;

   procedure Test_Context (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Context;
   end Test_Context;

   procedure Test_Device (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Device;
   end Test_Device;

   procedure Test_Hello_World (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Hello_World;
   end Test_Hello_World;

   procedure Test_Memory (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Memory;
   end Test_Memory;

   procedure Test_Platform (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Platform;
   end Test_Platform;

   procedure Test_Vector_Passing (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Vector_Passing;
   end Test_Vector_Passing;

   procedure Test_Vectors (Test : in out Test_Case'Class) is
      pragma Unreferenced (Test);
   begin
      CL_Test.Vectors;
   end Test_Vectors;

   overriding procedure Register_Tests (Test : in out Test_Case) is
   begin
      Registration.Register_Wrapper
        (Test, Test_Context'Access, "legacy context driver");
      Registration.Register_Wrapper
        (Test, Test_Device'Access, "legacy device driver");
      Registration.Register_Wrapper
        (Test, Test_Hello_World'Access, "legacy hello-world driver");
      Registration.Register_Wrapper
        (Test, Test_Memory'Access, "legacy memory driver");
      Registration.Register_Wrapper
        (Test, Test_Platform'Access, "legacy platform driver");
      Registration.Register_Wrapper
        (Test, Test_Vector_Passing'Access, "legacy vector-passing driver");
      Registration.Register_Wrapper
        (Test, Test_Vectors'Access, "legacy vectors driver");
   end Register_Tests;

end CL_Test.Legacy_Drivers;