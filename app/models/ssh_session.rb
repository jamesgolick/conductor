class SshSession
  class ResultSet < Ssh::ResultProxy
    attr_accessor :cancelled

    def initialize; end

    def cancelled?
      cancelled
    end
  end

  attr_reader :commands, :ssh

  def initialize(*hosts, &block)
    @commands = []
    @ssh      = Ssh.new(*hosts)
    instance_eval(&block)
  end

  def run(*args)
    @commands << [:run, *args]
  end

  def put(*args)
    @commands << [:put, *args]
  end

  def before_command(&block)
    @before_command = block
  end

  def on_data(&block)
    @on_data = block
  end

  def execute
    returning ResultSet.new do |r|
      commands.each do |c|
        run_before_command(c)
        r << ssh.send(c.shift, *c, &@on_data)
        if !r.last.successful?
          r.cancelled = true
          break
        end
      end
    end
  end

  protected
    def run_before_command(command)
      unless @before_command.nil?
        @before_command.call(command.first, command[1])
      end
    end
end

