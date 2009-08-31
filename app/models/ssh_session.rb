require 'net/ssh'
require 'net/sftp'

class SshSession
  attr_reader :ssh, :host

  def initialize(host)
    @ssh  = Net::SSH::Multi.start
    @host = host
    ssh.use(host, :forward_agent => true)
  end

  def run(command)
    log = ""

    channel = ssh.exec(command) do |channel, stream, data|
      line = build_line(stream, log, data)

      yield(line) if block_given?

      log << line
    end
    ssh.loop

    CommandResult.new(host, log, channel[:exit_status])
  end

  def upload(file)
    sftp.upload!(file, file)
  end

  def put(value, location)
    sftp.file.open(location, "w") do |f|
      f.puts value
    end
  end

  protected
    def sftp
      @sftp ||= Net::SFTP.start(hostname, username)
    end

    def hostname
      host.split("@").last
    end

    def username
      host.split("@").first
    end

    def build_line(stream, log, data)
      returning("") do |line|
        line << "[#{stream.to_s.upcase}]: " if log.ends_with?("\n") || log.blank?
        line << data
      end
    end
end

