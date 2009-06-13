require File.expand_path('../../test_helper', __FILE__)

class Ec2Test < Test::Unit::TestCase
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

      assert_equal Ec2.test_responses[:run_instances], @ec2.run_instances(opts)
      assert_equal opts, Ec2.test_mode_calls[:run_instances].first
    end
  end
end
