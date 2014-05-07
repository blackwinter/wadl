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

module WADL

  class HTTPMethod < HasDocs

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
      headers['Accept'] = expect_representation.mediaType if args[:expect_representation]

      method.response.build(HTTPRequest.execute(
        uri, name, args[:send_representation], headers))
    end

  end

end
