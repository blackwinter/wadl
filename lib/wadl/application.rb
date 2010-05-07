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

  class Application < HasDocs

    in_document 'application'
    has_one Resources
    has_many HTTPMethod, RepresentationFormat, FaultFormat

    def self.from_wadl(wadl)
      wadl = wadl.read if wadl.respond_to?(:read)
      doc = REXML::Document.new(wadl)

      application = from_element(nil, doc.root, need_finalization = [])
      need_finalization.each { |x| x.finalize_creation }

      application
    end

    def find_resource(symbol, *args, &block)
      resource_list.find_resource(symbol, *args, &block)
    end

    def resource(symbol)
      resource_list.resource(symbol)
    end

    def find_resource_by_path(symbol, *args, &block)
      resource_list.find_resource_by_path(symbol, *args, &block)
    end

    def finalize_creation
      resource_list.resources.each { |r|
        define_singleton(r, :id,   'resource_list.find_resource')
        define_singleton(r, :path, 'resource_list.find_resource_by_path')
      } if resource_list
    end

  end

end
