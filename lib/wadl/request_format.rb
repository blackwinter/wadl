#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2006-2008 Leonard Richardson                                  #
# Copyright (C) 2010-2013 Jens Wille                                          #
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

require 'wadl'

module WADL

  class RequestFormat < HasDocs

    include RepresentationContainer

    in_document 'request'
    has_many RepresentationFormat, Param

    # Returns a URI and a set of HTTP headers for this request.
    def uri(resource, args = {})
      uri = resource.uri(args)

      query_values  = args[:query]   || {}
      header_values = args[:headers] || {}

      params.each { |param|
        name = param.name

        if param.style == 'header'
          value = header_values[name] || header_values[name.to_sym]
          value = param % value

          uri.headers[name] = value if value
        else
          value = query_values[name] || query_values[name.to_sym]
          value = param.format(value, nil, 'query')

          uri.query << value if value && !value.empty?
        end
      }

      uri
    end

  end

end
