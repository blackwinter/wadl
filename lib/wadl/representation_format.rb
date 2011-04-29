#--
###############################################################################
#                                                                             #
# A component of wadl, the super cheap Ruby WADL client.                      #
#                                                                             #
# Copyright (C) 2006-2008 Leonard Richardson                                  #
# Copyright (C) 2010-2011 Jens Wille                                          #
#                                                                             #
# Authors:                                                                    #
#     Leonard Richardson <leonardr@segfault.org> (Original author)            #
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
require 'wadl'

module WADL

  class RepresentationFormat < HasDocs

    in_document 'representation'
    has_attributes :id, :mediaType, :element
    has_many Param
    may_be_reference

    def is_form_representation?
      mediaType == 'application/x-www-form-urlencoded' || mediaType == 'multipart/form-data'
    end

    # Creates a representation by plugging a set of parameters
    # into a representation format.
    def %(values)
      unless mediaType == 'application/x-www-form-urlencoded'
        raise "wadl.rb can't instantiate a representation of type #{mediaType}"
      end

      representation = []

      params.each { |param|
        name = param.name

        if param.fixed
          p_values = [param.fixed]
        elsif p_values = values[name] || values[name.to_sym]
          p_values = [p_values] if !param.repeating? || !p_values.respond_to?(:each) || p_values.respond_to?(:to_str)
        else
          raise ArgumentError, "Your proposed representation is missing a value for #{param.name}" if param.required?
        end

        p_values.each { |v| representation << "#{CGI::escape(name)}=#{CGI::escape(v.to_s)}" } if p_values
      }

      representation.join('&')
    end

  end

end
