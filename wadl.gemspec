# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wadl}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = %q{2010-05-07}
  s.description = %q{Ruby client for the Web Application Description Language.}
  s.email = ["leonardr@segfault.org", "jens.wille@uni-koeln.de"]
  s.extra_rdoc_files = ["COPYING", "ChangeLog", "README"]
  s.files = ["lib/wadl.rb", "lib/wadl/version.rb", "README", "ChangeLog", "Rakefile", "COPYING", "examples/yahoo.wadl", "examples/YahooSearch.rb", "examples/crummy.rb", "examples/yahoo.rb", "examples/crummy.wadl", "examples/delicious.wadl", "examples/YahooSearch.wadl", "examples/delicious.rb"]
  s.homepage = %q{http://github.com/blackwinter/wadl}
  s.rdoc_options = ["--charset", "UTF-8", "--title", "wadl Application documentation", "--main", "README", "--line-numbers", "--inline-source", "--all"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Ruby client for the Web Application Description Language.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-open-uri>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 0"])
    else
      s.add_dependency(%q<rest-open-uri>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 0"])
    end
  else
    s.add_dependency(%q<rest-open-uri>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 0"])
  end
end
