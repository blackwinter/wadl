#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2006-2008 Leonard Richardson                                  #
# Copyright (C) 2010-2014 Jens Wille                                          #
#                                                                             #
# Authors:                                                                    #
#     Leonard Richardson <leonardr@segfault.org> (Original author)            #
#     Jens Wille <jens.wille@gmail.com>                                       #
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

require 'net/https'
require 'safe_yaml/load'

module WADL

  require_oauth 'client/helper'

  class HTTPRequest

    DEFAULT_METHOD = :get

    DEFAULT_USER_AGENT   = "Ruby WADL client/#{VERSION}"
    DEFAULT_CONTENT_TYPE = 'application/x-www-form-urlencoded'

    OAUTH_HEADER = 'Authorization'
    OAUTH_PREFIX = 'OAuth:'

    class << self

      def execute(uri, *args)
        new(uri).execute(*args)
      end

      def oauth_header(args)
        return unless valid_oauth_args?(args)
        [OAUTH_HEADER, "#{OAUTH_PREFIX}#{args.to_yaml}"]
      end

      def valid_oauth_args?(args)
        args.is_a?(Array) && args.size == 4
      end

    end

    def initialize(uri)
      self.uri = URI(uri)
    end

    def start
      self.http = Net::HTTP.start(
        uri.hostname, uri.port,
        use_ssl: uri.scheme == 'https'
      )

      self
    end

    def finish
      http.finish if started?
      self
    end

    def started?
      http && http.started?
    end

    def execute(*args)
      start unless started?

      req = prepare_request(*args)
      res = http.request(req)

      HTTPResponse.new(res)
    end

    private

    attr_accessor :uri, :http

    def prepare_request(method, body, headers)
      req = make_request(method || DEFAULT_METHOD)
      req.body = body if req.request_body_permitted?

      set_headers(req, headers)

      req
    end

    def make_request(method)
      Net::HTTP.const_get(method.to_s.capitalize).new(uri)
    rescue NameError
      raise ArgumentError, "method not supported: #{method}"
    end

    def set_headers(req, headers)
      set_oauth_header(req, headers)

      headers['User-Agent']   ||= DEFAULT_USER_AGENT
      headers['Content-Type'] ||= DEFAULT_CONTENT_TYPE

      headers.each { |key, value|
        Array(value).each { |val| req.add_field(key, val) }
      }
    end

    def set_oauth_header(req, headers)
      args = SafeYAML.load($') if headers[OAUTH_HEADER] =~ /\A#{OAUTH_PREFIX}/
      return unless self.class.valid_oauth_args?(args)

      headers[OAUTH_HEADER] = OAuth::Client::Helper.new(req,
        request_uri:      req.request_uri,
        consumer:         consumer = OAuth::Consumer.new(*args[0, 2]),
        token:            OAuth::AccessToken.new(consumer, *args[2, 2]),
        scheme:           'header',
        signature_method: 'HMAC-SHA1'
      ).header
    end

  end

end
