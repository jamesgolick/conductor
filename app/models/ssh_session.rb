require 'net/ssh'
require 'net/sftp'

class SshSession
  attr_reader :ssh, :hosts

  def initialize(*hosts)
    @ssh   = Net::SSH::Multi.start
    @hosts = hosts

    hosts.each do |h|
      ssh.use(h, :forward_agent => true)
    end
  end

  def run(command)
    log = ""

    channel = ssh.exec(command) do |channel, stream, data|
      line = build_line(stream, log, data)

      yield(line) if block_given?

      log << line
    end
    ssh.loop
  end

  protected
    def build_line(stream, log, data)
      returning("") do |line|
        line << "[#{stream.to_s.upcase}]: " if log.ends_with?("\n") || log.blank?
        line << data
      end
    end
end

