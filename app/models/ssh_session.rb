class SshSession
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
    returning [] do |r|
      commands.each do |c|
        run_before_command(c)
        r << ssh.send(c.shift, *c, &@on_data)
        break unless r.last.successful?
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

