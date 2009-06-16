require 'fileutils'

class Bootstrapper
  attr_reader :instance

  def initialize(instance)
    @instance = instance
  end

  def bootstrap
    `#{cmd}`
    instance.bootstrapped!
  end

  protected
    def cmd
      "#{script_location} #{instance.application.name} #{instance.application.cookbook_clone_url} #{instance.dns_name}"
    end

    def script_location
      Rails.root + "/script/bootstrap"
    end
end

