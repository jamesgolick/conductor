require 'json/pure'

class Dna < HashWithIndifferentAccess
  attr_reader :cookbook, :role, :environment, :instance

  def initialize(environment, role, cookbook, instance)
    super()
    @role        = role
    @cookbook    = cookbook
    @environment = environment
    @instance    = instance

    set_initial_run_list
    set_master
    eval_attributes_file
    merge_environment_dna
  end

  def method_missing(name, *args, &block)
    args.empty? ? self[name] : self[name] = args.first
  end

  protected
    def set_initial_run_list
      self[:run_list] = ["role[#{role}]"]
    end

    def eval_attributes_file
      instance_eval(cookbook.read("attributes.rb"), "attributes.rb")
    end

    def merge_environment_dna
      merge!(environment.to_dna)
    end

    def set_master
      self[:master] = true if environment.master == instance
    end
end

