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

  def exec
    commands.each do |c|
      result = ssh.send(c.shift, *c)
      return result unless result.successful?
    end
  end
end

