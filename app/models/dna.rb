class Dna < HashWithIndifferentAccess
  def initialize(role)
    super
    self[:run_list] = ["roles[#{role}]"]
  end
end

