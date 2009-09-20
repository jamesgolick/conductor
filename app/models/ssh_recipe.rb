class SshRecipe
  attr_reader :commands

  def initialize(&block)
    @commands = []
    instance_eval(&block)
  end

  def run(*args)
    @commands << [:run, *args]
  end

  def put(*args)
    @commands << [:put, *args]
  end

  def exec(session)
    commands.each do |c|
      result = session.send(c.shift, *c)
      return result unless result.successful?
    end
  end
end

