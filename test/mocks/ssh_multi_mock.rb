class SSHMultiMock
  attr_reader :servers_used, :responses

  def initialize
    @servers_used = []
    @responses    = {}
  end

  def use(host)
    @servers_used << host
  end

  def add_command_response(command, *response)
    responses[command] ||= []
    responses[command] << response
  end

  def exec(command, &block)
    responses[command].each do |response|
      block.call(*response)
    end
  end
end

