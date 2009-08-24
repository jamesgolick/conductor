class Dna < HashWithIndifferentAccess
  attr_reader :cookbook, :role

  def initialize(role, cookbook)
    super()
    @role     = role
    @cookbook = cookbook

    set_initial_run_list
    eval_attributes_file
  end

  def method_missing(name, *args, &block)
    args.empty? ? self[name] : self[name] = args.first
  end

  protected
    def set_initial_run_list
      self[:run_list] = ["roles[#{role}]"]
    end

    def eval_attributes_file
      instance_eval(cookbook.read("attributes.rb"), "attributes.rb")
    end
end

