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

require 'set'
require 'wadl'

module WADL

  class Resource < HasDocs

    include ResourceContainer

    in_document 'resource'
    has_attributes :id, :path
    has_many Resource, HTTPMethod, Param, ResourceType
    may_be_reference  # not conforming to spec (20090831), but tests make use of it

    def initialize(*args)
      super
    end

    def dereference_with_context(child)
      ResourceAndAddress.new(child, parent.address)
    end

    # Returns a ResourceAndAddress object bound to this resource
    # and the given query variables.
    def bind(args = {})
      ResourceAndAddress.new(self).bind!(args)
    end

    # Sets basic auth parameters
    def with_basic_auth(user, pass, header = 'Authorization')
      bind(:headers => { header => "Basic #{["#{user}:#{pass}"].pack('m')}" })
    end

    # Sets OAuth parameters
    #
    # Args:
    #  :consumer_key
    #  :consumer_secret
    #  :access_token
    #  :token_secret
    def with_oauth(*args)
      header, prefix = HTTPMethod::OAUTH_HEADER, HTTPMethod::OAUTH_PREFIX
      bind(:headers => { header => "#{prefix}#{args.to_yaml}" })
    end

    def uri(args = {}, working_address = nil)
      address(working_address && working_address.deep_copy).uri(args)
    end

    # Returns an Address object refering to this resource
    def address(working_address = nil)
      working_address &&= working_address.deep_copy
      working_address ||= if parent.respond_to?(:base)
        address = Address.new
        address.path_fragments << parent.base
        address
      else
        parent.address.deep_copy
      end

      working_address.path_fragments << path.dup

      # Install path, query, and header parameters in the Address. These
      # may override existing parameters with the same names, but if
      # you've got a WADL application that works that way, you should
      # have bound parameters to values earlier.
      new_path_fragments = []
      embedded_param_names = Set.new(Address.embedded_param_names(path))

      params.each { |param|
        name = param.name

        if embedded_param_names.include?(name)
          working_address.path_params[name] = param
        else
          if param.style == 'query'
            working_address.query_params[name] = param
          elsif param.style == 'header'
            working_address.header_params[name] = param
          else
            new_path_fragments << param
            working_address.path_params[name] = param
          end
        end
      }

      working_address.path_fragments << new_path_fragments unless new_path_fragments.empty?

      working_address
    end

    def representation_for(http_method, request = true, all = false)
      method = find_method_by_http_method(http_method)
      representations = (request ? method.request : method.response).representations

      all ? representations : representations[0]
    end

    def find_by_id(id)
      id = id.to_s
      resources.find { |r| r.dereference.id == id }
    end

    # Find HTTP methods in this resource and in the mixed-in types
    def each_http_method
      [self, *resource_types].each { |t| t.http_methods.each { |m| yield m } }
    end

    def find_method_by_id(id)
      id = id.to_s
      each_http_method { |m| return m if m.dereference.id == id }
    end

    def find_method_by_http_method(action)
      action = action.to_s.downcase
      each_http_method { |m| return m if m.dereference.name.downcase == action }
    end

    # Methods for reading or writing this resource
    %w[get post put delete].each { |method|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          find_method_by_http_method(:#{method}).call(self, *args, &block)
        end
      EOT
    }

  end

end
