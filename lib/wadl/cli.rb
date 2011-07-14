#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2010-2011 Jens Wille                                          #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# wadl is free software; you can redistribute it and/or modify it under the   #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# wadl is distributed in the hope that it will be useful, but WITHOUT ANY     #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with wadl. If not, see <http://www.gnu.org/licenses/>.                #
#                                                                             #
###############################################################################
#++

require 'cgi'
require 'stringio'
require 'nuggets/util/cli'
require 'wadl'

begin
  require 'oauth/cli'
rescue LoadError
  warn "For OAuth support, install the `oauth' library."
end

module WADL

  class CLI < ::Util::CLI

    OPTION_RE          = %r{\A--?(.+?)(?:=(.+))?\z}
    RESOURCE_PATH_RE   = %r{[. /]}
    QUERY_SEPARATOR_RE = %r{[&;]}n
    ARRAY_SUFFIX_RE    = %r{\[\]\z}
    HASH_SUFFIX_RE     = %r{\[(.+)\]\z}

    class << self

      def usage(*)
        "#{super} <resource-path> [-- arguments]"
      end

      def defaults
        super.merge(
          :config            => 'config.yaml',
          :method            => 'GET',
          :user              => ENV['USER'] || '',
          :request_token_url => '%s/oauth/request_token',
          :access_token_url  => '%s/oauth/access_token',
          :authorize_url     => '%s/oauth/authorize'
        )
      end

    end

    attr_reader :resource_path, :opts

    def run(arguments)
      if options.delete(:dump_config)
        stdout.puts(YAML.dump(options))
        exit
      end

      parse_arguments(arguments)
      quit if resource_path.empty?

      quit "WADL location is required! (Specify with '--wadl' or see '--help')" unless options[:wadl]
      options[:wadl] %= options[:base_url] if options[:base_url]

      if debug = options[:debug]
        debug = 1 unless debug.is_a?(Integer)

        stderr.puts api.paths if debug >= 1
        stderr.puts api       if debug >= 2
      end

      response = auth_resource.send(options[:method].downcase, :query => opts)

      stderr.puts response.code.join(' ')
      stdout.puts response.representation unless response.code.first =~ /\A[45]/
    end

    def api
      @api ||= WADL::Application.from_wadl(open(options[:wadl]))
    end

    def resource
      @resource ||= begin
        path = [options[:api_base], *resource_path].compact.join('/').split(RESOURCE_PATH_RE)
        path.inject(api) { |m, n| m.send(:find_resource_by_path, n) } or quit "Resource not found: #{path.join('/')}"
      end
    end

    def auth_resource
      @auth_resource ||= options[:skip_auth] ? resource            :
                         options[:oauth]     ? oauth_resource      :
                         options[:basic]     ? basic_auth_resource :
                                               resource
    end

    def reset(stdin = STDIN, stdout = STDOUT, stderr = STDERR)
      super
      @api = @resource = @auth_resource = nil
    end

    private

    def parse_options(arguments)
      quit if arguments.empty?
      super
    end

    def parse_arguments(arguments)
      @resource_path, @opts, skip_next = [], {}, false
      @opts.update(options[:query]) if options[:query]

      arguments.each_with_index { |arg, index|
        if skip_next
          skip_next = false
          next
        end

        if arg =~ OPTION_RE
          key, value, next_arg = $1, $2, arguments[index + 1]

          add_param(opts, key, value || if next_arg =~ OPTION_RE
            '1'  # "true"
          else
            skip_next = true
            next_arg
          end)
        else
          resource_path << arg
        end
      }
    end

    def parse_query(query)
      params = {}

      query.split(QUERY_SEPARATOR_RE).each { |pair|
        add_param(params, *pair.split('=', 2).map { |v| CGI.unescape(v) })
      }

      params
    end

    def add_param(params, key, value)
      case key
        when HASH_SUFFIX_RE
          sub = $1

          if (param = params[key]).is_a?(Hash)
            param[sub] = value
            return
          else
            value = { sub => value }
          end
        when ARRAY_SUFFIX_RE
          if (param = params[key]).is_a?(Array)
            param << value
            return
          else
            value = [value]
          end
      end

      params[key] = value
    end

    def basic_auth_resource
      user, pass = options.values_at(:user, :password)
      pass ||= ask("Password for user #{user}: ") { |q| q.echo = false }

      quit 'USER and PASSWORD required' unless user && pass

      resource.with_basic_auth(user, pass)
    end

    def oauth_resource
      consumer_key, consumer_secret = options.values_at(:consumer_key, :consumer_secret)
      access_token, token_secret    = options.values_at(:token, :secret)

      quit "CONSUMER KEY and SECRET required" unless consumer_key && consumer_secret

      unless access_token && token_secret
        access_token, token_secret = oauthorize(consumer_key, consumer_secret)
        quit 'Authorization failed!?' unless access_token && token_secret
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
        config[:token]  = access_token
        config[:secret] = token_secret

        File.open(options[:config], 'w') { |f| YAML.dump(config, f) }
      end

      [access_token, token_secret]
    end

    def opts(opts)
      opts.on('-c', '--config YAML', "Config file [Default: #{defaults[:config]}#{' (currently not present)' unless File.readable?(defaults[:config])}]") { |config|
        options[:config] = config
      }

      opts.separator ''

      opts.on('-w', '--wadl FILE_OR_URL', "Path or URL to WADL file [Required]") { |wadl|
        options[:wadl] = wadl
      }

      opts.on('-m', '--method METHOD', "Request method [Default: #{defaults[:method]}]") { |method|
        options[:method] = method.upcase
      }

      opts.on('-a', '--api-base PATH', "Base path for API") { |api_base|
        options[:api_base] = api_base
      }

      opts.on('-q', '--query QUERY', "Query string to pass to request") { |query|
        options[:query] = parse_query(query)
      }

      opts.separator ''

      opts.on('--skip-auth', "Skip any authentication") {
        options[:skip_auth] = true
      }

      opts.separator ''
      opts.separator 'Basic Auth options:'

      opts.on('-B', '--basic', "Perform Basic Auth") {
        options[:basic] = true
      }

      opts.separator ''

      opts.on('--user USER', "User name") { |user|
        options[:user] = user
      }

      opts.on('--password PASSWORD', "Password for user") { |password|
        options[:password] = password
      }

      opts.separator ''
      opts.separator 'OAuth options:'

      opts.on('-O', '--oauth', "Perform OAuth") {
        options[:oauth] = true
      }

      opts.separator ''

      opts.on('--consumer-key KEY', "Consumer key to use") { |consumer_key|
        options[:consumer_key] = consumer_key
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
    end

    def generic_opts(opts)
      super

      opts.on('-d', '--debug [LEVEL]', Integer, 'Enable debugging output') { |level|
        options[:debug] = level || true
      }

      opts.on('-D', '--dump-config', 'Dump config and exit') {
        options[:dump_config] = true
      }
    end

    def post_opts(opts)
      opts.separator ''
      opts.separator "PATH may be separated by any of #{RESOURCE_PATH_RE.source}."
    end

  end

end
