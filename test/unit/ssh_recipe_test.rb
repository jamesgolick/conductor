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
end
