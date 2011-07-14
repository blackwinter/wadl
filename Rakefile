require File.expand_path(%q{../lib/wadl/version}, __FILE__)

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name         => %q{wadl},
      :version      => WADL::VERSION,
      :summary      => %q{Ruby client for the Web Application Description Language.},
      :authors      => ['Leonard Richardson', 'Jens Wille'],
      :email        => ['leonardr@segfault.org', 'jens.wille@uni-koeln.de'],
      :homepage     => :blackwinter,
      :dependencies => %w[rest-open-uri mime-types] << ['ruby-nuggets', '>= 0.7.3']
    }
  }}
rescue LoadError => err
  warn "Please install the `hen' gem. (#{err})"
end
