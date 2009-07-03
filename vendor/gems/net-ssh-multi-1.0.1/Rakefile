begin
  require 'echoe'
rescue LoadError
  abort "You'll need to have `echoe' installed to use Net::SSH::Multi's Rakefile"
end

require './lib/net/ssh/multi/version'

version = Net::SSH::Multi::Version::STRING.dup
if ENV['SNAPSHOT'].to_i == 1
  version << "." << Time.now.utc.strftime("%Y%m%d%H%M%S")
end

Echoe.new('net-ssh-multi', version) do |p|
  p.changelog        = "CHANGELOG.rdoc"

  p.author           = "Jamis Buck"
  p.email            = "jamis@jamisbuck.org"
  p.summary          = "Control multiple Net::SSH connections via a single interface"
  p.url              = "http://net-ssh.rubyforge.org/multi"

  p.dependencies     = ["net-ssh >=1.99.2", "net-ssh-gateway >=0.99.0"]

  p.need_zip         = true
  p.include_rakefile = true

  p.rdoc_pattern     = /^(lib|README.rdoc|CHANGELOG.rdoc)/
end
