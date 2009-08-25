class Address < ActiveRecord::Base
  belongs_to    :environment
  belongs_to    :instance

  before_create :allocate_address

  protected
    def allocate_address
      self.address = ec2.allocate_address
    end

    def ec2
      @ec2 ||= Ec2.new
    end
end
