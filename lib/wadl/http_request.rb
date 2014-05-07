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

require 'safe_yaml/load'

require_relative 'rest-open-uri'

module WADL

  require_oauth 'client/helper'

  class HTTPRequest

    DEFAULT_USER_AGENT   = "Ruby WADL client/#{VERSION}"
    DEFAULT_CONTENT_TYPE = 'application/x-www-form-urlencoded'

    OAUTH_HEADER = 'Authorization'
    OAUTH_PREFIX = 'OAuth:'

    class << self

      def execute(uri, method = :get, body = nil, headers = {})
        new.execute(uri, method, body, headers)
      end

      def oauth_header(args)
        return unless valid_oauth_args?(args)
        [OAUTH_HEADER, "#{OAUTH_PREFIX}#{args.to_yaml}"]
      end

      def valid_oauth_args?(args)
        args.is_a?(Array) && args.size == 4
      end

    end

    def execute(uri, method, body, headers)
      headers[:method] = method
      headers[:body]   = body

      set_default_headers(headers)
      set_oauth_header(uri, headers)

      open(uri, headers)
    rescue OpenURI::HTTPError => err
      err.io
    end

    private

    def set_default_headers(headers)
      headers['User-Agent']   ||= DEFAULT_USER_AGENT
      headers['Content-Type'] ||= DEFAULT_CONTENT_TYPE
    end

    def set_oauth_header(uri, headers)
      args = SafeYAML.load($') if headers[OAUTH_HEADER] =~ /\A#{OAUTH_PREFIX}/
      return unless self.class.valid_oauth_args?(args)

      request = OpenURI::Methods[headers[:method]].new(uri.to_s)

      headers[OAUTH_HEADER] = OAuth::Client::Helper.new(request,
        request_uri:      request.path,
        consumer:         consumer = OAuth::Consumer.new(*args[0, 2]),
        token:            OAuth::AccessToken.new(consumer, *args[2, 2]),
        scheme:           'header',
        signature_method: 'HMAC-SHA1'
      ).header
    end

  end

end
