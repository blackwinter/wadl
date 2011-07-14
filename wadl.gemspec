# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wadl}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Leonard Richardson}, %q{Jens Wille}]
  s.date = %q{2011-07-14}
  s.description = %q{Ruby client for the Web Application Description Language.}
  s.email = [%q{leonardr@segfault.org}, %q{jens.wille@uni-koeln.de}]
  s.executables = [%q{wadl}]
  s.extra_rdoc_files = [%q{README}, %q{COPYING}, %q{ChangeLog}]
  s.files = [%q{lib/wadl.rb}, %q{lib/wadl/resource_and_address.rb}, %q{lib/wadl/response.rb}, %q{lib/wadl/resource_container.rb}, %q{lib/wadl/representation_format.rb}, %q{lib/wadl/representation_container.rb}, %q{lib/wadl/documentation.rb}, %q{lib/wadl/param.rb}, %q{lib/wadl/cli.rb}, %q{lib/wadl/xml_representation.rb}, %q{lib/wadl/uri_parts.rb}, %q{lib/wadl/application.rb}, %q{lib/wadl/http_method.rb}, %q{lib/wadl/request_format.rb}, %q{lib/wadl/fault.rb}, %q{lib/wadl/link.rb}, %q{lib/wadl/resource_type.rb}, %q{lib/wadl/option.rb}, %q{lib/wadl/resource.rb}, %q{lib/wadl/address.rb}, %q{lib/wadl/version.rb}, %q{lib/wadl/has_docs.rb}, %q{lib/wadl/fault_format.rb}, %q{lib/wadl/response_format.rb}, %q{lib/wadl/cheap_schema.rb}, %q{lib/wadl/resources.rb}, %q{bin/wadl}, %q{README}, %q{ChangeLog}, %q{Rakefile}, %q{TODO}, %q{COPYING}, %q{example/yahoo.wadl}, %q{example/README}, %q{example/YahooSearch.rb}, %q{example/crummy.rb}, %q{example/yahoo.rb}, %q{example/crummy.wadl}, %q{example/delicious.wadl}, %q{example/config.yaml}, %q{example/YahooSearch.wadl}, %q{example/delicious.rb}, %q{test/wadl_test.rb}]
  s.homepage = %q{http://github.com/blackwinter/wadl}
  s.rdoc_options = [%q{--charset}, %q{UTF-8}, %q{--main}, %q{README}, %q{--title}, %q{wadl Application documentation (v0.2.4)}, %q{--line-numbers}, %q{--all}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{Ruby client for the Web Application Description Language.}

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
