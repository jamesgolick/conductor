require File.expand_path('../../test_helper', __FILE__)

class Ec2Test < Test::Unit::TestCase
  def setup
    Ec2.test_mode_calls = {}
    File.stubs(:read).with(Rails.root.to_s + "/config/aws.yml").returns("
test:
  :access_key_id: test_access_key_id
  :secret_access_key: test_secret_access_key")
  end

  context "In production mode" do
    setup do
      Ec2.mode = :production
      @ec2 = Ec2.new
    end

    should "forward the calls on to the aws gem" do
      mock_connection = mock
      mock_connection.expects(:run_instances).
        with("ami-whatever", 1, 1, ['default'], 'conductor-key',
              '', nil, 'c1.medium', nil, nil, 'us-east-1c')
      @ec2.stubs(:connection).returns(mock_connection)
      @ec2.run_instances :ami => "ami-whatever",
                         :instance_type => "c1.medium",
                         :availability_zone => "us-east-1c",
                         :groups => ['default'],
                         :keypair => 'conductor-key'
    end

    should "destroy an instance" do
      mock_connection = mock
      mock_connection.expects(:terminate_instances).with(['i-12345'])
      @ec2.stubs(:connection).returns(mock_connection)
      @ec2.terminate_instances('i-12345')
    end

    should "allocate an address" do
      mock_connection = mock
      mock_connection.expects(:allocate_address).returns("127.0.0.1")
      @ec2.stubs(:connection).returns(mock_connection)
      @ec2.allocate_address
    end

    should "associate an address" do
      mock_connection = mock
      mock_connection.expects(:associate_address).with("i-12345", "127.0.0.1")
      @ec2.stubs(:connection).returns(mock_connection)
      @ec2.associate_address("i-12345", "127.0.0.1")
    end
  end

  context "In test mode" do
    setup do
      Ec2.mode = :test
      @ec2 = Ec2.new
    end

    should "store the calls in an array" do
      opts = { :ami => "ami-whatever",
               :instance_type => "c1.medium",
               :availability_zone => "us-east-1c",
               :groups => ['default'],
               :keypair => 'conductor-key' }

      assert_equal [Ec2.test_responses[:run_instances]], @ec2.run_instances(opts)
      assert_equal opts, Ec2.test_mode_calls[:run_instances].first
    end

    should "store the calls to terminate_instances in an array" do
      @ec2.terminate_instances "i-42i1"
      assert_equal ["i-42i1"], @ec2.test_mode_calls[:terminate_instances].first
    end

    should "return the test response for allocate address" do
      assert_equal "127.0.0.1", @ec2.allocate_address
    end

    should "store the associated addresses" do
      @ec2.associate_address("i-12345", "127.0.0.1")
      assert_equal ["i-12345", "127.0.0.1"], Ec2.test_mode_calls[:associate_address].first
    end
  end

  context "The credentials" do
    should "be grabbed from config/aws.yml" do
      assert_equal "test_access_key_id", Ec2.credentials[:access_key_id]
      assert_equal "test_secret_access_key", Ec2.credentials[:secret_access_key]
    end
  end

  context "The connection" do
    should "be made to the RightAws api" do
      RightAws::Ec2.expects(:new).
        with("test_access_key_id", "test_secret_access_key")
      Ec2.new.send :connection
    end
  end

  context "Resetting test mode" do
    should "revert test_mode_calls to an empty hash" do
      Ec2.test_mode_calls[:run_instances] = []
      Ec2.reset_test_mode!
      assert_equal({}, Ec2.test_mode_calls)
    end
  end

  context "Describing instances" do
    should "defer directly to the connection" do
      ec2 = Ec2.new
      ec2.send(:connection).expects(:describe_instances).with("i-12345")
      ec2.describe_instances("i-12345")
    end
  end
end
