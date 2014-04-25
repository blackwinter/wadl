require File.expand_path(%q{../lib/wadl/version}, __FILE__)

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name         => %q{wadl},
      :version      => WADL::VERSION,
      :summary      => %q{Ruby client for the Web Application Description Language.},
      :authors      => ['Leonard Richardson', 'Jens Wille'],
      :email        => ['leonardr@segfault.org', 'jens.wille@gmail.com'],
      :license      => %q{AGPL-3.0},
      :homepage     => :blackwinter,
      :dependencies => %w[cyclops rf-rest-open-uri mime-types]
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem. (#{err})"
end
