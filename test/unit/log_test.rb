require File.expand_path('../../test_helper', __FILE__)

class LogTest < ActiveSupport::TestCase
  context "Appending data to a log" do
    setup do
      @log = Log.new :log => "something, something else\n"
      @log.append "and some other stuff"
    end

    should "save the appended data to the log" do
      expected =  "something, something else\nand some other stuff"
      assert_equal expected, @log.reload.log
    end
  end

  context "Getting the last line of the log" do
    should "return the last line" do
      @log = Log.new :log => "a\nb\nc"
      assert_equal "c", @log.last_line
    end

    should "return '' if there's no log" do
      assert_equal '', Log.new.last_line
    end
  end
end

