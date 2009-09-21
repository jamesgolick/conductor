class SshSession
  class ResultSet < Ssh::ResultProxy
    attr_accessor :cancelled

    def initialize; end

    def cancelled?
      cancelled
    end

    def failed_hosts
      failures.first.failures.map(&:host)
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
      run_commands(r)
    end
  end

  protected
    def run_before_command(command)
      unless @before_command.nil?
        @before_command.call(command.first, command[1])
      end
    end

    def run_commands(result_set)
      commands.each do |c|
        run_before_command(c)
        result_set << ssh.send(c.shift, *c, &@on_data)
        if !result_set.last.successful?
          result_set.cancelled = true if c != commands.last
          break
        end
      end
    end
end

