# -*- encoding: utf-8 -*-
# stub: wadl 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wadl"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Leonard Richardson", "Jens Wille"]
  s.date = "2014-11-28"
  s.description = "Ruby client for the Web Application Description Language."
  s.email = "jens.wille@gmail.com"
  s.executables = ["wadl"]
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.files = ["COPYING", "ChangeLog", "README", "Rakefile", "TODO", "bin/wadl", "example/README", "example/YahooSearch.rb", "example/YahooSearch.wadl", "example/config.yaml", "example/crummy.rb", "example/crummy.wadl", "example/delicious.rb", "example/delicious.wadl", "example/yahoo.rb", "example/yahoo.wadl", "lib/wadl.rb", "lib/wadl/address.rb", "lib/wadl/application.rb", "lib/wadl/cheap_schema.rb", "lib/wadl/cli.rb", "lib/wadl/documentation.rb", "lib/wadl/fault.rb", "lib/wadl/fault_format.rb", "lib/wadl/has_docs.rb", "lib/wadl/http_method.rb", "lib/wadl/http_request.rb", "lib/wadl/http_response.rb", "lib/wadl/link.rb", "lib/wadl/option.rb", "lib/wadl/param.rb", "lib/wadl/representation_container.rb", "lib/wadl/representation_format.rb", "lib/wadl/request_format.rb", "lib/wadl/resource.rb", "lib/wadl/resource_and_address.rb", "lib/wadl/resource_container.rb", "lib/wadl/resource_type.rb", "lib/wadl/resources.rb", "lib/wadl/response.rb", "lib/wadl/response_format.rb", "lib/wadl/uri_parts.rb", "lib/wadl/version.rb", "lib/wadl/xml_representation.rb", "test/wadl_test.rb"]
  s.homepage = "http://github.com/blackwinter/wadl"
  s.licenses = ["AGPL-3.0"]
  s.rdoc_options = ["--title", "wadl Application documentation (v0.3.0)", "--charset", "UTF-8", "--line-numbers", "--all", "--main", "README"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.4"
  s.summary = "Super cheap Ruby WADL client."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
      s.add_runtime_dependency(%q<mime-types>, ["~> 2.4"])
      s.add_runtime_dependency(%q<safe_yaml>, ["~> 1.0"])
      s.add_development_dependency(%q<hen>, [">= 0.8.0", "~> 0.8"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
    else
      s.add_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
      s.add_dependency(%q<mime-types>, ["~> 2.4"])
      s.add_dependency(%q<safe_yaml>, ["~> 1.0"])
      s.add_dependency(%q<hen>, [">= 0.8.0", "~> 0.8"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>, [">= 0.0.4", "~> 0.0"])
    s.add_dependency(%q<mime-types>, ["~> 2.4"])
    s.add_dependency(%q<safe_yaml>, ["~> 1.0"])
    s.add_dependency(%q<hen>, [">= 0.8.0", "~> 0.8"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
  end
end
