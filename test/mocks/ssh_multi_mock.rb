class SSHMultiMock
  attr_reader :servers_used

  def use(host)
    @servers_used ||= []
    @servers_used << host
  end
end

