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
require 'rf-rest-open-uri'

module WADL

  require_oauth 'client/helper'

  class HTTPMethod < HasDocs

    OAUTH_HEADER = 'Authorization'
    OAUTH_PREFIX = 'OAuth:'

    in_document 'method'
    as_collection 'http_methods'
    has_required :id, :name
    has_one RequestFormat
    has_many ResponseFormat
    may_be_reference

    def response
      responses.first
    end

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
      args = SafeYAML.load($') if headers[OAUTH_HEADER] =~ /\A#{OAUTH_PREFIX}/
      return unless args.is_a?(Array) && args.size == 4

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
