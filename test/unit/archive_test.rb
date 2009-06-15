require File.expand_path('../../test_helper', __FILE__)

class ArchiveTest < Test::Unit::TestCase
  context "Creating an archive" do
    should "tar the directory to the supplied path" do
      archive_path = "/tmp/12345.tar.gz"
      to_archive   = Rails.root + "/test/fixtures/bootstrap"
      Archive.expects(:`).with("tar --file=#{archive_path} -czv #{to_archive}")
      @archive = Archive.create(to_archive, 
                                 archive_path)
    end
  end
end
