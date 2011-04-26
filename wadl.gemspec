# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wadl}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = %q{2011-04-26}
  s.description = %q{Ruby client for the Web Application Description Language.}
  s.email = ["leonardr@segfault.org", "jens.wille@uni-koeln.de"]
  s.executables = ["wadl"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/wadl.rb", "lib/wadl/resource_and_address.rb", "lib/wadl/response.rb", "lib/wadl/resource_container.rb", "lib/wadl/representation_format.rb", "lib/wadl/representation_container.rb", "lib/wadl/documentation.rb", "lib/wadl/param.rb", "lib/wadl/cli.rb", "lib/wadl/xml_representation.rb", "lib/wadl/uri_parts.rb", "lib/wadl/application.rb", "lib/wadl/http_method.rb", "lib/wadl/request_format.rb", "lib/wadl/fault.rb", "lib/wadl/link.rb", "lib/wadl/resource_type.rb", "lib/wadl/option.rb", "lib/wadl/resource.rb", "lib/wadl/address.rb", "lib/wadl/version.rb", "lib/wadl/has_docs.rb", "lib/wadl/fault_format.rb", "lib/wadl/response_format.rb", "lib/wadl/cheap_schema.rb", "lib/wadl/resources.rb", "bin/wadl", "README", "ChangeLog", "Rakefile", "TODO", "COPYING", "example/yahoo.wadl", "example/README", "example/YahooSearch.rb", "example/crummy.rb", "example/yahoo.rb", "example/crummy.wadl", "example/delicious.wadl", "example/config.yaml", "example/YahooSearch.wadl", "example/delicious.rb", "test/wadl_test.rb"]
  s.homepage = %q{http://github.com/blackwinter/wadl}
  s.rdoc_options = ["--charset", "UTF-8", "--title", "wadl Application documentation (v0.2.2)", "--main", "README", "--line-numbers", "--all"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Ruby client for the Web Application Description Language.}

  if s.respond_to? :specification_version then
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
