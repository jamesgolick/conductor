class ChefRunner
  attr_reader :servers

  def initialize(*servers)
    @servers = servers
  end

  def run_chef
    Net::SSH::Multi.start do |session|
      servers.each do |s|
        session.use s
      end

      session.open_channel do |channel|
        channel.exec "chef-solo -j /etc/chef/dna.json"
      end
    end
  end
end

