require %q{lib/wadl/version}

begin
  require 'hen'

  Hen.lay! {{
    :gem => {
      :name         => %q{wadl},
      :version      => WADL::VERSION,
      :summary      => %q{Ruby client for the Web Application Description Language.},
      :authors      => ['Leonard Richardson', 'Jens Wille'],
      :email        => ['leonardr@segfault.org', 'jens.wille@uni-koeln.de'],
      :homepage     => 'http://github.com/blackwinter/wadl',
      :files        => FileList['lib/**/*.rb'].to_a,
      :extra_files  => FileList['[A-Z]*', 'examples/*'].to_a,
      :dependencies => %w[rest-open-uri mime-types]
    }
  }}
rescue LoadError
  abort "Please install the 'hen' gem first."
end

### Place your custom Rake tasks here.
