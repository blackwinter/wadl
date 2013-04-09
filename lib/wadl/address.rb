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

  # The Address class keeps track of the user's path through a resource
  # graph. Values for WADL parameters may be specified at any time using
  # the bind method. An Address cannot be turned into a URI and header
  # set until all required parameters have been bound to values.
  #
  # An Address object is built up through calls to Resource#address

  class Address

    attr_reader :path_fragments, :query_vars, :headers,
                :path_params, :query_params, :header_params

    def self.embedded_param_names(fragment)
      fragment.scan(/\{(.+?)\}/).flatten
    end

    def initialize(path_fragments = [], query_vars = [], headers = {},
                   path_params = {}, query_params = {}, header_params = {})
      @path_fragments, @query_vars, @headers = path_fragments, query_vars, headers
      @path_params, @query_params, @header_params = path_params, query_params, header_params

      @auth = {}
    end

    # Perform a deep copy.
    def deep_copy
      address = Address.new(
        _deep_copy_array(@path_fragments),
        _deep_copy_array(@query_vars),
        _deep_copy_hash(@headers),
        @path_params.dup,
        @query_params.dup,
        @header_params.dup
      )

      @auth.each { |header, value| address.auth(header, value) }

      address
    end

    def to_s
      "Address:\n"                                            <<
      " Path fragments: #{@path_fragments.inspect}\n"         <<
      " Query variables: #{@query_vars.inspect}\n"            <<
      " Header variables: #{@headers.inspect}\n"              <<
      " Authorization parameters: #{@auth.inspect}\n"         <<
      " Unbound path parameters: #{@path_params.inspect}\n"   <<
      " Unbound query parameters: #{@query_params.inspect}\n" <<
      " Unbound header parameters: #{@header_params.inspect}\n"
    end

    alias_method :inspect, :to_s

    # Binds some or all of the unbound variables in this address to values.
    def bind!(args = {})
      path_var_values   = args[:path]    || {}
      query_var_values  = args[:query]   || {}
      header_var_values = args[:headers] || {}

      @auth.each { |header, value| header_var_values[header] = value }.clear

      # Bind variables found in the path fragments.
      path_params_to_delete = []

      path_fragments.each { |fragment|
        if fragment.respond_to?(:to_str)
          # This fragment is a string which might contain {} substitutions.
          # Make any substitutions available to the provided path variables.
          self.class.embedded_param_names(fragment).each { |name|
            value = path_var_values[name] || path_var_values[name.to_sym]

            value = if param = path_params[name]
              path_params_to_delete << param
              param % value
            else
              Param.default.format(value, name)
            end

            fragment.gsub!("{#{name}}", value)
          }
        else
          # This fragment is an array of Param objects (style 'matrix'
          # or 'plain') which may be bound to strings. As substitutions
          # happen, the array will become a mixed array of Param objects
          # and strings.
          fragment.each_with_index { |param, i|
            next unless param.respond_to?(:name)

            name = param.name

            value = path_var_values[name] || path_var_values[name.to_sym]
            value = param % value
            fragment[i] = value if value

            path_params_to_delete << param
          }
        end
      }

      # Delete any embedded path parameters that are now bound from
      # our list of unbound parameters.
      path_params_to_delete.each { |p| path_params.delete(p.name) }

      # Bind query variable values to query parameters
      query_var_values.each { |name, value|
        param = query_params.delete(name.to_s)
        query_vars << param % value if param
      }

      # Bind header variables to header parameters
      header_var_values.each { |name, value|
        if param = header_params.delete(name.to_s)
          headers[name] = param % value
        else
          warn %Q{Ignoring unknown header parameter "#{name}"!}
        end
      }

      self
    end

    def auth(header, value)
      @auth[header] = value
      self
    end

    def uri(args = {})
      obj, uri = deep_copy.bind!(args), ''

      # Build the path
      obj.path_fragments.flatten.each { |fragment|
        if fragment.respond_to?(:to_str)
          embedded_param_names = self.class.embedded_param_names(fragment)

          unless embedded_param_names.empty?
            raise ArgumentError, %Q{Missing a value for required path parameter "#{embedded_param_names[0]}"!}
          end

          unless fragment.empty?
            uri << '/' unless uri.empty? || uri =~ /\/\z/
            uri << fragment
          end
        elsif fragment.required?
          # This is a required Param that was never bound to a value.
          raise ArgumentError, %Q{Missing a value for required path parameter "#{fragment.name}"!}
        end
      }

      # Hunt for required unbound query parameters.
      obj.query_params.each { |name, value|
        if value.required?
          raise ArgumentError, %Q{Missing a value for required query parameter "#{value.name}"!}
        end
      }

      # Hunt for required unbound header parameters.
      obj.header_params.each { |name, value|
        if value.required?
          raise ArgumentError, %Q{Missing a value for required header parameter "#{value.name}"!}
        end
      }

      URIParts.new(uri, obj.query_vars, obj.headers)
    end

    private

    def _deep_copy_hash(h)
      h.inject({}) { |h, (k, v)| h[k] = v && v.dup; h }
    end

    def _deep_copy_array(a)
      a.inject([]) { |a, e| a << (e && e.dup) }
    end

  end

end
