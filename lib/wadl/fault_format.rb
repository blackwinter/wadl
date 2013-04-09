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

  class FaultFormat < RepresentationFormat

    in_document 'fault'
    has_attributes :id, :mediaType, :element, :status
    has_many Param
    may_be_reference

    attr_writer :subclass

    def subclass
      attributes['href'] ? dereference.subclass : @subclass
    end

    # Define a custom subclass for this fault, so that the programmer
    # can rescue this particular fault.
    def self.from_element(*args)
      me = super

      me.subclass = if name = me.attributes['id']
        begin
          WADL::Faults.const_defined?(name) ?
            WADL::Faults.const_get(name) :
            WADL::Faults.const_set(name, Class.new(Fault))
        rescue NameError
          # This fault format's ID can't be a class name. Use the
          # generic subclass of Fault.
        end
      end || Fault unless me.attributes['href']

      me
    end

  end

end
