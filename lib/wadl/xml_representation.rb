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

require 'rexml/document'
require 'wadl'

module WADL

  # A module mixed in to REXML documents to make them representations in the
  # WADL sense.

  module XMLRepresentation

    def representation_of(format)
      @params = format.params
    end

    def lookup_param(name)
      param = @params.find { |p| p.name == name }

      raise ArgumentError, "No such param #{name}" unless param
      raise ArgumentError, "Param #{name} has no path!" unless param.path

      param
    end

    # Yields up each XML element for the given Param object.
    def each_by_param(param_name)
      REXML::XPath.each(self, lookup_param(param_name).path) { |e| yield e }
    end

    # Returns an XML element for the given Param object.
    def get_by_param(param_name)
      REXML::XPath.first(self, lookup_param(param_name).path)
    end

  end

end
