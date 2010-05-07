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

require 'wadl'

module WADL

  class Param < HasDocs

    in_document 'param'
    has_required :name
    has_attributes :type, :default, :style, :path, :required, :repeating, :fixed
    has_many Option, Link
    may_be_reference

    # cf. <http://www.w3.org/TR/xmlschema-2/#boolean>
    BOOLEAN_RE = %r{\A(?:true|1)\z}

    # A default Param object to use for a path parameter that is
    # only specified as a name in the path of a resource.
    def self.default
      @default ||= begin
        default = Param.new

        default.required = 'true'
        default.style    = 'plain'
        default.type     = 'xsd:string'

        default
      end
    end

    def required?
      required =~ BOOLEAN_RE
    end

    def repeating?
      repeating =~ BOOLEAN_RE
    end

    def inspect
      %Q{Param "#{name}"}
    end

    # Validates and formats a proposed value for this parameter. Returns
    # the formatted value. Raises an ArgumentError if the value
    # is invalid.
    #
    # The 'name' and 'style' arguments are used in conjunction with the
    # default Param object.
    def format(value, name = nil, style = nil)
      name  ||= self.name
      style ||= self.style

      value = fixed if fixed
      value ||= default if default

      unless value
        if required?
          raise ArgumentError, %Q{No value provided for required param "#{name}"!}
        else
          return '' # No value provided and none required.
        end
      end

      if value.respond_to?(:each) && !value.respond_to?(:to_str)
        if repeating?
          values = value
        else
          raise ArgumentError, %Q{Multiple values provided for single-value param "#{name}"}
        end
      else
        values = [value]
      end

      # If the param lists acceptable values in option tags, make sure that
      # all values are found in those tags.
      if options && !options.empty?
        values.each { |value|
          unless find_option(value)
            acceptable = options.map { |o| o.value }.join('", "')
            raise ArgumentError, %Q{"#{value}" is not among the acceptable parameter values ("#{acceptable}")}
          end
        }
      end

      if style == 'query' || parent.is_a?(RequestFormat) || (
        parent.respond_to?(:is_form_representation?) && parent.is_form_representation?
      )
        values.map { |v| "#{URI.escape(name)}=#{URI.escape(v.to_s)}" }.join('&')
      elsif style == 'matrix'
        if type == 'xsd:boolean'
          values.map { |v| ";#{name}" if v =~ BOOLEAN_RE }.compact.join
        else
          values.map { |v| ";#{URI.escape(name)}=#{URI.escape(v.to_s)}" if v }.compact.join
        end
      elsif style == 'header'
        values.join(',')
      else
        # All other cases: plain text representation.
        values.map { |v| URI.escape(v.to_s) }.join(',')
      end
    end

    alias_method :%, :format

  end

end
