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

  # Classes to keep track of the logical structure of a URI.

  class URIParts < Struct.new(:uri, :query, :headers)

    def to_s
      qs = "#{uri.include?('?') ? '&' : '?'}#{query_string}" unless query.empty?
      "#{uri}#{qs}"
    end

    alias_method :to_str, :to_s

    def inspect
      hs = " Plus headers: #{headers.inspect}" if headers
      "#{to_s}#{hs}"
    end

    def query_string
      query.join('&')
    end

    def hash(x)
      to_str.hash
    end

    def ==(x)
      x.respond_to?(:to_str) ? to_str == x : super
    end

  end

end
