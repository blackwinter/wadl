#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2006-2008 Leonard Richardson                                  #
# Copyright (C) 2010 Jens Wille                                               #
#                                                                             #
# Authors:                                                                    #
#     Leonard Richardson <leonardr@segfault.org> (Original author)            #
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

require 'yaml'
require 'rest-open-uri'
require 'wadl'

begin
  require 'oauth/client/helper'
rescue LoadError
  warn "For OAuth support, install the 'oauth' library."
end

module WADL

  class HTTPMethod < HasDocs

    OAUTH_HEADER = 'Authorization'
    OAUTH_PREFIX = 'OAuth:'

    in_document 'method'
    as_collection 'http_methods'
    has_required :id, :name
    has_one RequestFormat, ResponseFormat
    may_be_reference

    # Args:
    #  :path - Values for path parameters
    #  :query - Values for query parameters
    #  :headers - Values for header parameters
    #  :send_representation
    #  :expect_representation
    def call(resource, args = {})
      unless parent.respond_to?(:uri)
        raise "You can't call a method that's not attached to a resource! (You may have dereferenced a method when you shouldn't have)"
      end

      resource ||= parent
      method = dereference

      uri = method.request ? method.request.uri(resource, args) : resource.uri(args)
      headers = uri.headers.dup

      headers['Accept']       = expect_representation.mediaType if args[:expect_representation]
      headers['User-Agent']   = 'Ruby WADL client' unless headers['User-Agent']
      headers['Content-Type'] = 'application/x-www-form-urlencoded'
      headers[:method]        = name.downcase.to_sym
      headers[:body]          = args[:send_representation]

      set_oauth_header(headers, uri)

      response = begin
        open(uri, headers)
      rescue OpenURI::HTTPError => err
        err.io
      end

      method.response.build(response)
    end

    def set_oauth_header(headers, uri)
      args = headers[OAUTH_HEADER] or return

      yaml = args.dup
      yaml.sub!(/\A#{OAUTH_PREFIX}/, '') or return

      consumer_key, consumer_secret, access_token, token_secret = YAML.load(yaml)

      request = OpenURI::Methods[headers[:method]].new(uri.to_s)

      consumer = OAuth::Consumer.new(consumer_key, consumer_secret)
      token    = OAuth::AccessToken.new(consumer, access_token, token_secret)

      helper = OAuth::Client::Helper.new(request,
        :request_uri      => request.path,
        :consumer         => consumer,
        :token            => token,
        :scheme           => 'header',
        :signature_method => 'HMAC-SHA1'
      )

      headers[OAUTH_HEADER] = helper.header
    end

  end

end
