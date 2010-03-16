# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby_tubesday}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dana Contreras"]
  s.date = %q{2010-03-10}
  s.files = ["lib/ruby_tubesday.rb", "lib/ruby_tubesday/cache_policy.rb", "lib/ruby_tubesday/parser.rb", "ca-bundle.crt"]
  s.homepage = %q{http://github.com/dummied/ruby_tubesday}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Full-featured HTTP client library.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.1"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.1"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.1"])
  end
end
