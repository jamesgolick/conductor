require 'test_helper'

class SshRecipeTest < ActiveSupport::TestCase
  context "Instantiating an ssh recipe" do
    setup do
      @recipe = SshRecipe.new do
        put "asdf"
        run "ls -la"
        run "other stuffs"
      end
    end

    should "collect the commands" do
      assert_equal [:put, "asdf"], @recipe.commands[0]
      assert_equal [:run, "ls -la"], @recipe.commands[1]
      assert_equal [:run, "other stuffs"], @recipe.commands[2]
    end
  end

  context "Running a recipe" do
    setup do
      @recipe  = SshRecipe.new do
        run "ls -la"
        run "rm -Rf /"
      end
      @session = SshSession.new
    end

    should "run it on the supplied session" do
      @session.expects(:run).with("ls -la").returns(stub(:successful? => true))
      @session.expects(:run).with("rm -Rf /").returns(stub(:successful? => true))
      @recipe.exec(@session)
    end

    context "when a command fails" do
      setup do
        @proxy = SshSession::ResultProxy.new([stub(:successful? => false)])
        @session.stubs(:run).with("ls -la").returns(@proxy)
        @session.expects(:run).with("rm -Rf /").never
      end

      should "stop running the commands and return the failing resultproxy" do
        assert_equal @proxy, @recipe.exec(@session)
      end
    end
  end
end
