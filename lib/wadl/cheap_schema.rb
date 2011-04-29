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

require 'wadl'

module WADL

  # A cheap way of defining an XML schema as Ruby classes and then parsing
  # documents into instances of those classes.

  class CheapSchema

    @may_be_reference        = false
    @contents_are_mixed_data = false

    ATTRIBUTES = %w[names members collections required_attributes attributes]

    class << self

      attr_reader(*ATTRIBUTES)

      def init
        @names, @members, @collections = {}, {}, {}
        @required_attributes, @attributes = [], []
      end

      def inherit(from)
        init

        ATTRIBUTES.each { |attr|
          value = from.send(attr)
          instance_variable_set("@#{attr}", value.dup) if value
        }

        %w[may_be_reference contents_are_mixed_data].each { |attr|
          instance_variable_set("@#{attr}", from.instance_variable_get("@#{attr}"))
        }
      end

      def inherited(klass)
        klass.inherit(self)
      end

      def may_be_reference?
        @may_be_reference
      end

      def in_document(element_name)
        @names[:element]    = element_name
        @names[:member]     = element_name
        @names[:collection] = element_name + 's'
      end

      def as_collection(collection_name)
        @names[:collection] = collection_name
      end

      def as_member(member_name)
        @names[:member] = member_name
      end

      def contents_are_mixed_data
        @contents_are_mixed_data = true
      end

      def has_one(*classes)
        classes.each { |klass|
          @members[klass.names[:element]] = klass
          dereferencing_instance_accessor(klass.names[:member])
        }
      end

      def has_many(*classes)
        classes.each { |klass|
          @collections[klass.names[:element]] = klass

          collection_name = klass.names[:collection]
          dereferencing_instance_accessor(collection_name)

          # Define a method for finding a specific element of this
          # collection.
          class_eval <<-EOT, __FILE__, __LINE__ + 1
            def find_#{klass.names[:element]}(*args, &block)
              block ||= begin
                name = args.shift.to_s
                lambda { |match| match.matches?(name) }
              end

              auto_dereference = args.shift
              auto_dereference = true if auto_dereference.nil?

              match = #{collection_name}.find { |match|
                block[match] || (
                  #{klass}.may_be_reference? &&
                  auto_dereference &&
                  block[match.dereference]
                )
              }

              match && auto_dereference ? match.dereference : match
            end
          EOT
        }
      end

      def dereferencing_instance_accessor(*symbols)
        define_dereferencing_accessors(symbols,
          'd, v = dereference, :@%s; ' <<
          'd.instance_variable_get(v) if d.instance_variable_defined?(v)',
          'dereference.instance_variable_set(:@%s, value)'
        )
      end

      def dereferencing_attr_accessor(*symbols)
        define_dereferencing_accessors(symbols,
          'dereference.attributes["%s"]',
          'dereference.attributes["%s"] = value'
        )
      end

      def has_attributes(*names)
        has_required_or_attributes(names, @attributes)
      end

      def has_required(*names)
        has_required_or_attributes(names, @required_attributes)
      end

      def may_be_reference
        @may_be_reference = true

        find_method_name = "find_#{names[:element]}"

        class_eval <<-EOT, __FILE__, __LINE__ + 1
          def dereference
            return self unless href = attributes['href']

            unless @referenced
              p = self

              until @referenced || !p
                begin
                  p = p.parent
                end until !p || p.respond_to?(:#{find_method_name})

                @referenced = p.#{find_method_name}(href, false) if p
              end
            end

            dereference_with_context(@referenced) if @referenced
          end
        EOT
      end

      # Turn an XML element into an instance of this class.
      def from_element(parent, element, need_finalization)
        attributes = element.attributes

        me = new
        me.parent = parent

        @collections.each { |name, klass|
          me.instance_variable_set("@#{klass.names[:collection]}", [])
        }

        if may_be_reference? and href = attributes['href']
          # Handle objects that are just references to other objects
          # somewhere above this one in the hierarchy
          href = href.dup
          href.sub!(/\A#/, '') or warn "Warning: HREF #{href} should be ##{href}"

          me.attributes['href'] = href
        else
          # Handle this element's attributes
          @required_attributes.each { |name|
            name = name.to_s

            raise ArgumentError, %Q{Missing required attribute "#{name}" in element: #{element}} unless attributes[name]

            me.attributes[name] = attributes[name]
            me.index_key = attributes[name] if name == @index_attribute
          }

          @attributes.each { |name|
            name = name.to_s

            me.attributes[name] = attributes[name]
            me.index_key = attributes[name] if name == @index_attribute
          }
        end

        # Handle this element's children.
        if @contents_are_mixed_data
          me.instance_variable_set(:@contents, element.children)
        else
          element.each_element { |child|
            if klass = @members[child.name] || @collections[child.name]
              object = klass.from_element(me, child, need_finalization)

              if klass == @members[child.name]
                instance_variable_name = "@#{klass.names[:member]}"

                if me.instance_variable_defined?(instance_variable_name)
                  raise "#{name} can only have one #{klass.name}, but several were specified in element: #{element}"
                end

                me.instance_variable_set(instance_variable_name, object)
              else
                me.instance_variable_get("@#{klass.names[:collection]}") << object
              end
            end
          }
        end

        need_finalization << me if me.respond_to?(:finalize_creation)

        me
      end

      private

      def define_dereferencing_accessors(symbols, getter, setter)
        symbols.each { |name|
          name = name.to_s

          class_eval <<-EOT, __FILE__, __LINE__ + 1 unless name =~ /\W/
            def #{name}; #{getter % name}; end
            def #{name}=(value); #{setter % name}; end
          EOT
        }
      end

      def has_required_or_attributes(names, var)
        names.each { |name|
          var << name
          @index_attribute ||= name.to_s
          name == :href ? attr_accessor(name) : dereferencing_attr_accessor(name)
        }
      end

    end

    attr_accessor :index_key, :href, :parent
    attr_reader :attributes

    def initialize
      @attributes, @contents, @referenced = {}, nil, nil
    end

    # This object is a reference to another object. This method returns
    # an object that acts like the other object, but also contains any
    # neccessary context about this object. See the ResourceAndAddress
    # implementation, in which a dereferenced resource contains
    # information about the parent of the resource that referenced it
    # (otherwise, there's no way to build the URI).
    def dereference_with_context(referent)
      referent
    end

    # A null implementation so that foo.dereference will always return the
    # "real" object.
    def dereference
      self
    end

    # Returns whether or not the given name matches this object.
    # By default, checks the index key for this class.
    def matches?(name)
      index_key == name
    end

    def each_attribute
      [self.class.required_attributes, self.class.attributes].each { |list|
        list.each { |attr|
          val = attributes[attr.to_s]
          yield attr, val if val
        }
      }
    end

    def each_member
      self.class.members.each_value { |member_class|
        member = send(member_class.names[:member])
        yield member if member
      }
    end

    def each_collection
      self.class.collections.each_value { |collection_class|
        collection = send(collection_class.names[:collection])
        yield collection if collection && !collection.empty?
      }
    end

    def paths(level = default = 0)
      klass, paths = self.class, []
      return paths if klass.may_be_reference? && attributes['href']

      if klass == Resource
        path = attributes['path']
        paths << [level, path] if path
      elsif klass == HTTPMethod
        paths << [level]
      end

      each_member { |member|
        paths.concat(member.paths(level))
      }

      each_collection { |collection|
        collection.each { |member| paths.concat(member.paths(level + 1)) }
      }

      if default
        memo = []

        paths.map { |level, path|
          if path
            memo.slice!(level..-1)
            memo[level] = path

            nil  # ignore
          else
            memo.join('/')
          end
        }.compact
      else
        paths
      end
    end

    def to_s(indent = 0, collection = false)
      klass = self.class

      a = '  '
      i = a * indent
      s = "#{collection ? a * (indent - 1) + '- ' : i}#{klass.name}\n"

      if klass.may_be_reference? and href = attributes['href']
        s << "#{i}= href=#{href}\n"
      else
        each_attribute { |attr, val|
          s << "#{i}* #{attr}=#{val}\n"
        }

        each_member { |member|
          s << member.to_s(indent + 1)
        }

        each_collection { |collection|
          s << "#{i}> Collection of #{collection.size} #{collection.class}(s)\n"
          collection.each { |member| s << member.to_s(indent + 2, true) }
        }

        if @contents && !@contents.empty?
          sep = '-' * 80
          s << "#{sep}\n#{@contents.join(' ').strip}\n#{sep}\n"
        end
      end

      s
    end

  end

end

# Simple backport for Ruby <= 1.8.5
class Object  # :nodoc:
  def instance_variable_defined?(sym); instance_eval("defined?(#{sym})"); end
end unless Object.method_defined?(:instance_variable_defined?)
