require 'json/pure'

class Dna < HashWithIndifferentAccess
  attr_reader :cookbook, :role, :environment

  def initialize(environment, role, cookbook)
    super()
    @role        = role
    @cookbook    = cookbook
    @environment = environment

    set_initial_run_list
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
end

