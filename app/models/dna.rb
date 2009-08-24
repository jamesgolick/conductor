class Dna < HashWithIndifferentAccess
  def initialize(role)
    super
    self[:run_list] = ["roles[#{role}]"]
  end

  def method_missing(name, *args, &block)
    args.empty? ? self[name] : self[name] = args.first
  end
end

