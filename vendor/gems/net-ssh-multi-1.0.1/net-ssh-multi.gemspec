Gem::Specification.new do |s|
  s.name = %q{net-ssh-multi}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jamis Buck"]
  s.date = %q{2009-02-01}
  s.description = %q{Control multiple Net::SSH connections via a single interface}
  s.email = %q{jamis@jamisbuck.org}
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "lib/net/ssh/multi/channel.rb", "lib/net/ssh/multi/channel_proxy.rb", "lib/net/ssh/multi/dynamic_server.rb", "lib/net/ssh/multi/pending_connection.rb", "lib/net/ssh/multi/server.rb", "lib/net/ssh/multi/server_list.rb", "lib/net/ssh/multi/session.rb", "lib/net/ssh/multi/session_actions.rb", "lib/net/ssh/multi/subsession.rb", "lib/net/ssh/multi/version.rb", "lib/net/ssh/multi.rb", "README.rdoc"]
  s.files = ["CHANGELOG.rdoc", "lib/net/ssh/multi/channel.rb", "lib/net/ssh/multi/channel_proxy.rb", "lib/net/ssh/multi/dynamic_server.rb", "lib/net/ssh/multi/pending_connection.rb", "lib/net/ssh/multi/server.rb", "lib/net/ssh/multi/server_list.rb", "lib/net/ssh/multi/session.rb", "lib/net/ssh/multi/session_actions.rb", "lib/net/ssh/multi/subsession.rb", "lib/net/ssh/multi/version.rb", "lib/net/ssh/multi.rb", "Manifest", "Rakefile", "README.rdoc", "setup.rb", "test/channel_test.rb", "test/common.rb", "test/multi_test.rb", "test/server_test.rb", "test/session_actions_test.rb", "test/session_test.rb", "test/test_all.rb", "net-ssh-multi.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://net-ssh.rubyforge.org/multi}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Net-ssh-multi", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{net-ssh-multi}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Control multiple Net::SSH connections via a single interface}
  s.test_files = ["test/test_all.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<net-ssh>, [">= 1.99.2"])
      s.add_runtime_dependency(%q<net-ssh-gateway>, [">= 0.99.0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<net-ssh>, [">= 1.99.2"])
      s.add_dependency(%q<net-ssh-gateway>, [">= 0.99.0"])
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<net-ssh>, [">= 1.99.2"])
    s.add_dependency(%q<net-ssh-gateway>, [">= 0.99.0"])
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
