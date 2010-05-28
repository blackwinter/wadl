# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wadl}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = %q{2010-05-28}
  s.default_executable = %q{wadl}
  s.description = %q{Ruby client for the Web Application Description Language.}
  s.email = ["leonardr@segfault.org", "jens.wille@uni-koeln.de"]
  s.executables = ["wadl"]
  s.extra_rdoc_files = ["COPYING", "ChangeLog", "README"]
  s.files = ["lib/wadl.rb", "lib/wadl/resource_and_address.rb", "lib/wadl/response.rb", "lib/wadl/resource_container.rb", "lib/wadl/representation_format.rb", "lib/wadl/representation_container.rb", "lib/wadl/documentation.rb", "lib/wadl/param.rb", "lib/wadl/cli.rb", "lib/wadl/xml_representation.rb", "lib/wadl/uri_parts.rb", "lib/wadl/application.rb", "lib/wadl/http_method.rb", "lib/wadl/request_format.rb", "lib/wadl/fault.rb", "lib/wadl/link.rb", "lib/wadl/resource_type.rb", "lib/wadl/option.rb", "lib/wadl/resource.rb", "lib/wadl/address.rb", "lib/wadl/version.rb", "lib/wadl/has_docs.rb", "lib/wadl/fault_format.rb", "lib/wadl/response_format.rb", "lib/wadl/cheap_schema.rb", "lib/wadl/resources.rb", "README", "ChangeLog", "Rakefile", "TODO", "COPYING", "examples/yahoo.wadl", "examples/README", "examples/YahooSearch.rb", "examples/crummy.rb", "examples/yahoo.rb", "examples/crummy.wadl", "examples/delicious.wadl", "examples/config.yaml", "examples/YahooSearch.wadl", "examples/delicious.rb", "test/test_wadl.rb", "bin/wadl"]
  s.homepage = %q{http://github.com/blackwinter/wadl}
  s.rdoc_options = ["--line-numbers", "--main", "README", "--inline-source", "--charset", "UTF-8", "--title", "wadl Application documentation", "--all"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Ruby client for the Web Application Description Language.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
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
