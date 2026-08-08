with AUnit.Test_Cases;

with CL_Test.Context_Cases;
with CL_Test.Legacy_Drivers;

package body CL_Test.Suite is

   function Get return AUnit.Test_Suites.Access_Test_Suite is
      Suite : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
      Context_Tests : constant AUnit.Test_Cases.Test_Case_Access :=
        new CL_Test.Context_Cases.Test_Case;
      Legacy_Tests  : constant AUnit.Test_Cases.Test_Case_Access :=
        new CL_Test.Legacy_Drivers.Test_Case;
   begin
      AUnit.Test_Suites.Add_Test (Suite, Context_Tests);
      AUnit.Test_Suites.Add_Test (Suite, Legacy_Tests);
      return Suite;
   end Get;

end CL_Test.Suite;