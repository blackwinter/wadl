# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "wadl"
  s.version = "0.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = "2011-09-06"
  s.description = "Ruby client for the Web Application Description Language."
  s.email = ["leonardr@segfault.org", "jens.wille@uni-koeln.de"]
  s.executables = ["wadl"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["lib/wadl.rb", "lib/wadl/uri_parts.rb", "lib/wadl/resource.rb", "lib/wadl/response.rb", "lib/wadl/option.rb", "lib/wadl/param.rb", "lib/wadl/application.rb", "lib/wadl/resource_and_address.rb", "lib/wadl/fault_format.rb", "lib/wadl/version.rb", "lib/wadl/link.rb", "lib/wadl/response_format.rb", "lib/wadl/resources.rb", "lib/wadl/representation_container.rb", "lib/wadl/cli.rb", "lib/wadl/address.rb", "lib/wadl/http_method.rb", "lib/wadl/has_docs.rb", "lib/wadl/xml_representation.rb", "lib/wadl/cheap_schema.rb", "lib/wadl/resource_container.rb", "lib/wadl/resource_type.rb", "lib/wadl/fault.rb", "lib/wadl/request_format.rb", "lib/wadl/representation_format.rb", "lib/wadl/documentation.rb", "bin/wadl", "ChangeLog", "COPYING", "README", "Rakefile", "TODO", "example/YahooSearch.rb", "example/yahoo.rb", "example/crummy.wadl", "example/YahooSearch.wadl", "example/README", "example/delicious.wadl", "example/yahoo.wadl", "example/delicious.rb", "example/crummy.rb", "example/config.yaml", "test/wadl_test.rb"]
  s.homepage = "http://github.com/blackwinter/wadl"
  s.rdoc_options = ["--line-numbers", "--main", "README", "--all", "--charset", "UTF-8", "--title", "wadl Application documentation (v0.2.6)"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Ruby client for the Web Application Description Language."

  if s.respond_to? :specification_version then
    s.specification_version = 3

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
