require 'ostruct'

class SSHMultiMock
  attr_reader :servers_used, :responses, :exit_codes

  def initialize
    @servers_used = []
    @responses    = {}
    @exit_codes   = {}
  end

  def use(host)
    @servers_used << host
  end

  def add_command_response(command, *response)
    responses[command] ||= []
    responses[command] << response
  end

  def set_exit_code(command, code)
    exit_codes[command] = code
  end

  def exec(command, &block)
    responses[command].each do |response|
      block.call(*response)
    end

    OpenStruct.new(:channels => [{:exit_status => exit_codes[command]}])
  end

  def loop; end
end

