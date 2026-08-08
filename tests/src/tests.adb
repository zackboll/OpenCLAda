with AUnit.Reporter.Text;
with AUnit.Run;

with CL_Test.Suite;

procedure Tests is
   procedure Run is new AUnit.Run.Test_Runner (CL_Test.Suite.Get);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
   Run (Reporter);
end Tests;