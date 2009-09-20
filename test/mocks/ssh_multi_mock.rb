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

  def set_exit_code(host, command, code)
    exit_codes[host]        ||= {}
    exit_codes[host][command] = code
  end

  def exec(command, &block)
    responses[command].each do |response|
      block.call(*response)
    end

    OpenStruct.new(:channels => channels(command))
  end

  def loop; end

  protected
    def channels(command)
      exit_codes.map do |k, v|
        OpenStruct.new(:properties => {:host      => k, 
                                       :exit_code => v[command]})
      end
    end
end

