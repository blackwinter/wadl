require File.expand_path(%q{../lib/wadl/version}, __FILE__)

begin
  require 'hen'

  Hen.lay! {{
    gem: {
      name:         %q{wadl},
      version:      WADL::VERSION,
      summary:      %q{Super cheap Ruby WADL client.},
      description:  %q{Ruby client for the Web Application Description Language.},
      authors:      ['Leonard Richardson', 'Jens Wille'],
      email:        'jens.wille@gmail.com',
      license:      %q{AGPL-3.0},
      homepage:     :blackwinter,
      dependencies: %w[cyclops rf-rest-open-uri mime-types safe_yaml],

      required_ruby_version: '>= 1.9.3'
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem. (#{err})"
end
