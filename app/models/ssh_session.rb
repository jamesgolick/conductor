require 'net/ssh'

class SshSession
  attr_reader :ssh

  def initialize(host, &block)
    username, host = host.split('@')
    Net::SSH.start(host, username) do |ssh|
      @ssh = ssh
      instance_eval(&block) if block_given?
      ssh.loop
    end
  end

  def run(cmd)
    ssh.exec(cmd)
  end
end

