# -*- encoding: utf-8 -*-
# stub: wadl 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "wadl".freeze
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Leonard Richardson".freeze, "Jens Wille".freeze]
  s.date = "2016-04-08"
  s.description = "Ruby client for the Web Application Description Language.".freeze
  s.email = "jens.wille@gmail.com".freeze
  s.executables = ["wadl".freeze]
  s.extra_rdoc_files = ["README".freeze, "COPYING".freeze, "ChangeLog".freeze]
  s.files = ["COPYING".freeze, "ChangeLog".freeze, "README".freeze, "Rakefile".freeze, "TODO".freeze, "bin/wadl".freeze, "example/README".freeze, "example/YahooSearch.rb".freeze, "example/YahooSearch.wadl".freeze, "example/config.yaml".freeze, "example/crummy.rb".freeze, "example/crummy.wadl".freeze, "example/delicious.rb".freeze, "example/delicious.wadl".freeze, "example/yahoo.rb".freeze, "example/yahoo.wadl".freeze, "lib/wadl.rb".freeze, "lib/wadl/address.rb".freeze, "lib/wadl/application.rb".freeze, "lib/wadl/cheap_schema.rb".freeze, "lib/wadl/cli.rb".freeze, "lib/wadl/documentation.rb".freeze, "lib/wadl/fault.rb".freeze, "lib/wadl/fault_format.rb".freeze, "lib/wadl/has_docs.rb".freeze, "lib/wadl/http_method.rb".freeze, "lib/wadl/http_request.rb".freeze, "lib/wadl/http_response.rb".freeze, "lib/wadl/link.rb".freeze, "lib/wadl/option.rb".freeze, "lib/wadl/param.rb".freeze, "lib/wadl/representation_container.rb".freeze, "lib/wadl/representation_format.rb".freeze, "lib/wadl/request_format.rb".freeze, "lib/wadl/resource.rb".freeze, "lib/wadl/resource_and_address.rb".freeze, "lib/wadl/resource_container.rb".freeze, "lib/wadl/resource_type.rb".freeze, "lib/wadl/resources.rb".freeze, "lib/wadl/response.rb".freeze, "lib/wadl/response_format.rb".freeze, "lib/wadl/uri_parts.rb".freeze, "lib/wadl/version.rb".freeze, "lib/wadl/xml_representation.rb".freeze, "test/wadl_test.rb".freeze]
  s.homepage = "http://github.com/blackwinter/wadl".freeze
  s.licenses = ["AGPL-3.0".freeze]
  s.rdoc_options = ["--title".freeze, "wadl Application documentation (v0.3.1)".freeze, "--charset".freeze, "UTF-8".freeze, "--line-numbers".freeze, "--all".freeze, "--main".freeze, "README".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.6.2".freeze
  s.summary = "Super cheap Ruby WADL client.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cyclops>.freeze, ["~> 0.2"])
      s.add_runtime_dependency(%q<mime-types>.freeze, ["~> 3.0"])
      s.add_runtime_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<hen>.freeze, [">= 0.8.3", "~> 0.8"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<cyclops>.freeze, ["~> 0.2"])
      s.add_dependency(%q<mime-types>.freeze, ["~> 3.0"])
      s.add_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
      s.add_dependency(%q<hen>.freeze, [">= 0.8.3", "~> 0.8"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<cyclops>.freeze, ["~> 0.2"])
    s.add_dependency(%q<mime-types>.freeze, ["~> 3.0"])
    s.add_dependency(%q<safe_yaml>.freeze, ["~> 1.0"])
    s.add_dependency(%q<hen>.freeze, [">= 0.8.3", "~> 0.8"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
