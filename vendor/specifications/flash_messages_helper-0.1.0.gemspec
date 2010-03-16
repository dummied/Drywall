# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flash_messages_helper}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Deering"]
  s.date = %q{2010-01-19}
  s.email = %q{mdeering@mdeering.com}
  s.extra_rdoc_files = ["README.textile"]
  s.files = ["MIT-LICENSE", "README.textile", "Rakefile", "install.rb", "install.txt", "lib/flash_messages_helper.rb", "rails/init.rb", "spec/flash_messages_helper_spec.rb", "spec/test_helper.rb"]
  s.homepage = %q{http://github.com/mdeering/flash_messages_helper}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A simple yet configurable rails view helper for displaying flash messages.}
  s.test_files = ["spec/flash_messages_helper_spec.rb", "spec/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
