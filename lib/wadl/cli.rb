#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2010 Jens Wille                                               #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# wadl is free software; you can redistribute it and/or modify it under the   #
# terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 3 of the License, or (at your option) any later  #
# version.                                                                    #
#                                                                             #
# wadl is distributed in the hope that it will be useful, but WITHOUT ANY     #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more       #
# details.                                                                    #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with wadl. If not, see <http://www.gnu.org/licenses/>.                      #
#                                                                             #
###############################################################################
#++

require 'optparse'
require 'yaml'
require 'highline'
require 'stringio'
require 'wadl'

begin
  require 'oauth/cli'
rescue LoadError
  warn "For OAuth support, install the 'oauth' library."
end

module WADL

  class CLI

    USAGE = "Usage: #{$0} [-h|--help] [options] <resource-path> [-- arguments]"

    DEFAULTS = {
      :config            => 'config.yaml',
      :method            => 'GET',
      :user              => ENV['USER'] || '',
      :request_token_url => '%s/oauth/request_token',
      :access_token_url  => '%s/oauth/access_token',
      :authorize_url     => '%s/oauth/authorize'
    }

    OPTION_RE = %r{\A--?(\w+)}
    RESOURCE_PATH_RE = %r{[. /]}

    def self.execute(*args)
      new.execute(*args)
    end

    attr_reader :options, :config, :defaults
    attr_reader :stdin, :stdout, :stderr
    attr_reader :resource_path, :opts

    def initialize(defaults = DEFAULTS)
      @defaults = defaults

      reset

      # prevent backtrace on ^C
      trap(:INT) { exit 130 }
    end

    def execute(arguments = [], *inouterr)
      reset(*inouterr)

      abort USAGE if arguments.empty?
      parse_options(arguments, defaults)

      abort YAML.dump(options), 0, stdout if options.delete(:dump_config)

      parse_arguments(arguments)
      abort USAGE if resource_path.empty?

      abort 'WADL required' unless options[:wadl]
      options[:wadl] %= options[:base_url] if options[:base_url]

      response = auth_resource.send(options[:method].downcase, :query => opts)

      stderr.puts response.code.join(' ')
      stdout.puts response.representation unless response.code.first =~ /\A[45]/
    end

    def api
      @api ||= WADL::Application.from_wadl(open(options[:wadl]))
    end

    def resource
      @resource ||= begin
        path = [options[:api_base], *resource_path].compact.join(' ')
        path.split(RESOURCE_PATH_RE).inject(api) { |m, n| m.send(n) }
      end
    end

    def auth_resource
      @auth_resource ||= if options[:basic]
        basic_auth_resource
      elsif options[:oauth]
        oauth_resource
      else
        resource
      end
    end

    def reset(stdin = STDIN, stdout = STDOUT, stderr = STDERR)
      @stdin, @stdout, @stderr = stdin, stdout, stderr
      @api = @resource = @auth_resource = nil
      @options, @config = {}, {}
    end

    private

    def ask(question, &block)
      HighLine.new(stdin, stdout).ask(question, &block)
    end

    def abort(msg = nil, status = 1, output = stderr)
      output.puts msg if msg
      exit status
    end

    def parse_options(arguments, defaults)
      option_parser(defaults).parse!(arguments)

      config_file = options[:config] || defaults[:config]
      @config = YAML.load_file(config_file) if File.readable?(config_file)

      [config, defaults].each { |hash| hash.each { |key, value| options[key] ||= value } }
    end

    def parse_arguments(arguments)
      @resource_path, @opts, skip = [], {}, false

      arguments.each_with_index { |arg, index|
        if skip
          skip = false
          next
        end

        case arg
          when OPTION_RE
            key, value = $1, arguments[index + 1]

            value =~ OPTION_RE ? value = '1' : skip = true

            opts[key] = value
          else
            resource_path << arg
        end
      }
    end

    def basic_auth_resource
      user, pass = options.values_at(:user, :password)
      pass ||= ask("Password for user #{user}: ") { |q| q.echo = false }

      abort 'USER and PASSWORD required' unless user && pass

      resource.with_basic_auth(user, pass)
    end

    def oauth_resource
      consumer_key, consumer_secret = options.values_at(:consumer_key, :consumer_secret)
      access_token, token_secret    = options.values_at(:token, :secret)

      abort "CONSUMER KEY and SECRET required" unless consumer_key && consumer_secret

      unless access_token && token_secret
        access_token, token_secret = oauthorize(consumer_key, consumer_secret)
        abort 'Authorization failed!?' unless access_token && token_secret
      end

      resource.with_oauth(consumer_key, consumer_secret, access_token, token_secret)
    end

    def oauthorize(consumer_key, consumer_secret)
      strio, stdout = StringIO.new, self.stdout

      (class << strio; self; end).send(:define_method, :puts) { |*args|
        stdout.puts(*args)
        super
      }

      base_url = options[:base_url] || File.dirname(options[:wadl])

      OAuth::CLI.execute(strio, stdin, stderr, [
        '--consumer-key',      consumer_key,
        '--consumer-secret',   consumer_secret,
        '--request-token-url', options[:request_token_url] % base_url,
        '--access-token-url',  options[:access_token_url]  % base_url,
        '--authorize-url',     options[:authorize_url]     % base_url,
        '--callback-url',      'oob',
        'authorize'
      ])

      result = strio.string
      access_token = result[/^\s+oauth_token:\s+(.*)$/, 1]
      token_secret = result[/^\s+oauth_token_secret:\s+(.*)$/, 1]

      return unless access_token && token_secret

      if File.writable?(options[:config])
        config[:token]        = access_token
        config[:token_secret] = token_secret

        File.open(options[:config], 'w') { |f| YAML.dump(config, f) }
      end

      [access_token, token_secret]
    end

    def option_parser(defaults)
      OptionParser.new { |opts|
        opts.banner = USAGE

        opts.separator ''
        opts.separator 'Options:'

        opts.on('-c', '--config YAML', "Config file [Default: #{defaults[:config]}#{' (currently not present)' unless File.readable?(defaults[:config])}]") { |config|
          options[:config] = config
        }

        opts.separator ''

        opts.on('-w', '--wadl FILE_OR_URL', "Path or URL to WADL file") { |wadl|
          options[:wadl] = wadl
        }

        opts.on('-m', '--method METHOD', "Request method [Default: #{defaults[:method]}]") { |method|
          options[:method] = method.upcase
        }

        opts.on('-a', '--api-base PATH', "Base path for API") { |api_base|
          options[:api_base] = api_base
        }

        opts.separator ''
        opts.separator 'Basic auth options:'

        opts.on('-B', '--basic [USER]', "Perform Basic auth (with optional user)") { |user|
          options[:basic] = true
          options[:user] = user if user
        }

        opts.on('--password PASSWORD', "Password for user") { |password|
          options[:password] = password
        }

        opts.separator ''
        opts.separator 'OAuth options:'

        opts.on('-O', '--oauth [CONSUMER_KEY]', "Perform OAuth (with optional consumer key)") { |consumer_key|
          options[:oauth] = true
          options[:consumer_key] = consumer_key if consumer_key
        }

        opts.on('--consumer-secret SECRET', "Consumer secret to use") { |consumer_secret|
          options[:consumer_secret] = consumer_secret
        }

        opts.separator ''

        opts.on('--token TOKEN', "Access token to use") { |token|
          options[:token] = token
        }

        opts.on('--secret SECRET', "Token secret to use") { |secret|
          options[:secret] = secret
        }

        opts.separator ''

        opts.on('-b', '--base-url URL', "Base URL [Default: \"dirname\" of WADL]") { |base_url|
          options[:base_url] = base_url
        }

        opts.on('--request-token-url URL', "Request token URL [Default: #{defaults[:request_token_url] % 'BASE_URL'}]") { |request_token_url|
          options[:request_token_url] = request_token_url
        }

        opts.on('--access-token-url URL', "Access token URL [Default: #{defaults[:access_token_url] % 'BASE_URL'}]") { |access_token_url|
          options[:access_token_url] = access_token_url
        }

        opts.on('--authorize-url URL', "Authorize URL [Default: #{defaults[:authorize_url] % 'BASE_URL'}]") { |authorize_url|
          options[:authorize_url] = authorize_url
        }

        opts.separator ''
        opts.separator 'Generic options:'

        opts.on('-h', '--help', 'Print this help message and exit') {
          abort opts.to_s
        }

        opts.on('--version', 'Print program version and exit') {
          abort "#{File.basename($0)} v#{WADL::VERSION}"
        }

        opts.on('-D', '--dump-config', "Dump config and exit") {
          options[:dump_config] = true
        }
      }
    end

  end

end
