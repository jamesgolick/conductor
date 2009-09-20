require 'net/ssh'
require 'net/sftp'

class SshSession
  class Result
  end

  attr_reader :ssh, :hosts

  def initialize(*hosts)
    @ssh   = Net::SSH::Multi.start
    @hosts = hosts

    hosts.each do |h|
      ssh.use(h, :forward_agent => true)
    end
  end

  def run(command)
    channel = ssh.exec(command) do |channel, stream, data|
      yield(channel[:host], stream.to_sym, data) if block_given?
    end
    ssh.loop
    Result.new
  end
end

