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

require 'delegate'

module WADL

  # A resource bound beneath a certain address. Used to keep track of a
  # path through a twisting resource hierarchy that includes references.

  class ResourceAndAddress < DelegateClass(Resource)

    def initialize(resource, address = nil, combine_address_with_resource = true)
      @resource = resource
      @address  = combine_address_with_resource ? resource.address(address) : address

      super(resource)
    end

    # The id method is not delegated, because it's the name of a
    # (deprecated) built-in Ruby method. We wnat to delegate it.
    def id
      @resource.id
    end

    def to_s
      inspect
    end

    def inspect
      "ResourceAndAddress\n Resource: #{@resource}\n #{@address.inspect}"
    end

    def address
      @address
    end

    def bind(*args)
      ResourceAndAddress.new(@resource, @address.deep_copy, false).bind!(*args)
    end

    def bind!(args = {})
      @address.bind!(args)
      self
    end

    def auth(header, value)
      @address.auth(header, value)
      self
    end

    def uri(args = {})
      @address.deep_copy.bind!(args).uri
    end

    # method_missing is to catch generated methods that don't get delegated.
    def method_missing(name, *args, &block)
      if @resource.respond_to?(name)
        result = @resource.send(name, *args, &block)
        result.is_a?(Resource) ? ResourceAndAddress.new(result, @address.dup) : result
      else
        super
      end
    end

    # method_missing won't catch these guys because they were defined in
    # the delegation operation.
    def resource(*args, &block)
      resource = @resource.resource(*args, &block)
      resource && ResourceAndAddress.new(resource, @address)
    end

    def find_resource(*args, &block)
      resource = @resource.find_resource(*args, &block)
      resource && ResourceAndAddress.new(resource, @address)
    end

    def find_resource_by_path(*args, &block)
      resource = @resource.find_resource_by_path(*args, &block)
      resource && ResourceAndAddress.new(resource, @address)
    end

    Resource.define_http_methods(self)

  end

end
