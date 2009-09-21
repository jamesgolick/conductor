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

  def execute
    commands.each do |c|
      run_before_command(c)
      result = ssh.send(c.shift, *c)
      return result unless result.successful?
    end
  end

  protected
    def run_before_command(command)
      unless @before_command.nil?
        @before_command.call(command.first, command[1])
      end
    end
end

