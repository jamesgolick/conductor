class Ec2
  cattr_accessor :mode, :test_responses, :test_mode_calls

  self.test_mode_calls = {}
  self.test_responses  = {
    :run_instances => {
       :aws_image_id       => "ami-e444444d",
       :aws_reason         => "",
       :aws_state_code     => "0",
       :aws_owner          => "000000000888",
       :aws_instance_id    => "i-123f1234",
       :aws_reservation_id => "r-aabbccdd",
       :aws_state          => "pending",
       :dns_name           => "",
       :ssh_key_name       => "my_awesome_key",
       :aws_groups         => ["my_awesome_group"],
       :private_dns_name   => "",
       :aws_instance_type  => "m1.small",
       :aws_launch_time    => "2008-1-1T00:00:00.000Z",
       :aws_ramdisk_id     => "ari-8605e0ef",
       :aws_kernel_id      => "aki-9905e0f0",
       :ami_launch_index   => "0",
       :aws_availability_zone => "us-east-1b"
    }
  }

  def run_instances(opts)
    send("run_instances_#{mode}", opts)
  end

  protected
    def run_instances_production(opts)
      connection.run_instances(opts[:ami], 1, 1, opts[:groups], opts[:keypair], '',
                                nil, opts[:instance_type], nil, nil, 
                                  opts[:availability_zone])
    end

    def run_instances_test(opts)
      test_mode_calls[:run_instances] ||= []
      test_mode_calls[:run_instances] << opts
      test_responses[:run_instances]
    end

    def connection
    end
end
