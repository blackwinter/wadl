# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "wadl"
  s.version = "0.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = "2013-07-15"
  s.description = "Ruby client for the Web Application Description Language."
  s.email = ["leonardr@segfault.org", "jens.wille@gmail.com"]
  s.executables = ["wadl"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/wadl.rb", "lib/wadl/address.rb", "lib/wadl/application.rb", "lib/wadl/cheap_schema.rb", "lib/wadl/cli.rb", "lib/wadl/documentation.rb", "lib/wadl/fault.rb", "lib/wadl/fault_format.rb", "lib/wadl/has_docs.rb", "lib/wadl/http_method.rb", "lib/wadl/link.rb", "lib/wadl/option.rb", "lib/wadl/param.rb", "lib/wadl/representation_container.rb", "lib/wadl/representation_format.rb", "lib/wadl/request_format.rb", "lib/wadl/resource.rb", "lib/wadl/resource_and_address.rb", "lib/wadl/resource_container.rb", "lib/wadl/resource_type.rb", "lib/wadl/resources.rb", "lib/wadl/response.rb", "lib/wadl/response_format.rb", "lib/wadl/uri_parts.rb", "lib/wadl/version.rb", "lib/wadl/xml_representation.rb", "bin/wadl", "COPYING", "ChangeLog", "README", "Rakefile", "TODO", "example/README", "example/YahooSearch.rb", "example/YahooSearch.wadl", "example/config.yaml", "example/crummy.rb", "example/crummy.wadl", "example/delicious.rb", "example/delicious.wadl", "example/yahoo.rb", "example/yahoo.wadl", "test/wadl_test.rb"]
  s.homepage = "http://github.com/blackwinter/wadl"
  s.licenses = ["AGPL"]
  s.rdoc_options = ["--charset", "UTF-8", "--line-numbers", "--all", "--title", "wadl Application documentation (v0.2.7)", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.5"
  s.summary = "Ruby client for the Web Application Description Language."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-open-uri>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-nuggets>, [">= 0.7.3"])
    else
      s.add_dependency(%q<rest-open-uri>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 0"])
      s.add_dependency(%q<ruby-nuggets>, [">= 0.7.3"])
    end
  else
    s.add_dependency(%q<rest-open-uri>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 0"])
    s.add_dependency(%q<ruby-nuggets>, [">= 0.7.3"])
  end
end
