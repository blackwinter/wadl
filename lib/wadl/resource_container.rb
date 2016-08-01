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

  # A mixin for objects that contain resources. If you include this, be
  # sure to alias :find_resource to :find_resource_autogenerated
  # beforehand.

  module ResourceContainer

    def resource(name_or_id)
      name_or_id = name_or_id.to_s
      find_resource { |r| r.id == name_or_id || r.path == name_or_id }
    end

    def find_resource_by_path(path, auto_dereference = nil)
      path = path.to_s
      find_resource(auto_dereference) { |r| r.path == path }
    end

    def finalize_creation
      resources.each { |r|
        define_singleton(r, :id,   :find_resource)
        define_singleton(r, :path, :find_resource_by_path)
      } if resources
    end

  end

end