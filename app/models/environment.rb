class Environment < ActiveRecord::Base
  belongs_to :application

  has_many   :instances do
    def to_dna
      running.inject({}) do |memo, instance|
        memo[instance.role.to_sym] ||= []
        memo[instance.role.to_sym] << instance.private_dns_name
        memo
      end
    end
  end

  has_one :address
  belongs_to :master, :class_name => "Instance"

  validates_presence_of :name
  validates_presence_of :domain

  def has_database_server?
    instances.any?(&:mysql_master?)
  end

  def has_configured_db_server?
    instances.any? { |i| i.mysql_master? && i.deployed? }
  end

  def to_dna
    {
      :apps          => [application.name],
      :rails_env     => name,
      :servers       => instances.to_dna,
      :app_domain    => domain,
      :user          => application.name,
      :app_clone_url => application.clone_url
    }
  end

  def acquire_new_master
    next_master_id = next_potential_master.andand.id
    if next_master_id.present? && attempt_to_set_as_master(next_master_id)
      master.assign_address!(address || create_address)
    end
  end

  def attempt_to_set_as_master(next_master_id)
    self.class.update_all "master_id = #{next_master_id}", 
                          "master_id IS NULL AND id = #{id}"
    reload
    master_id == next_master_id
  end

  def notify_of(event, instance)
    if event == :launch && instance.app? && need_master?
      acquire_new_master
    elsif event == :termination && instance.app? && instance == master
      update_attribute :master_id, nil
      acquire_new_master
    elsif event == :running && need_master?
      acquire_new_master
    end

    deploy if event == :running && instances.configured.count > 1
  end

  def need_master?
    master.nil?
  end

  def deploy
    ChefDeploymentRunner.new(*instances.configured).perform_deployment
  end

  def cookbook_repository
    @cookbook_repo ||= CookbookRepository.new(application.cookbook_clone_url)
  end

  protected
    def next_potential_master
      instances.app.running.first
    end
end
