# wadl.rb (http://www.crummy.com/software/wadl.rb/)
# Super cheap Ruby WADL client
# by Leonard Richardson leonardr@segfault.org
# v20070217
# For more on WADL, see http://wadl.dev.java.net/

require 'delegate'
require 'rexml/document'
require 'set'
require 'cgi'

require 'rubygems'
require 'rest-open-uri'

begin
  require 'mime/types'
rescue LoadError
end

module WADL

  # A container for application-specific faults
  module Faults
  end

  #########################################################################
  #
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

          find_method_name = "find_#{klass.names[:element]}"

          # Define a method for finding a specific element of this
          # collection.
          # TODO: In Ruby 1.9, make match_block a block argument.
          define_method(find_method_name) { |name, *args|
            name = name.to_s

            match_block = args[0].respond_to?(:call) ?
              args[0] : lambda { |match| match.name_matches(name) }

            auto_dereference = args[1].nil? ? true : args[1]

            match = send(collection_name).find { |match|
              match_block.call(match) || (
                klass.may_be_reference? &&
                auto_dereference &&
                match_block.call(match.dereference)
              )
            }

            match && auto_dereference ? match.dereference : match
          }
        }
      end

      def dereferencing_instance_accessor(*symbols)
        symbols.each { |name|
          define_method(name) {
            d, v = dereference, "@#{name}"
            d.instance_variable_get(v) if d.instance_variable_defined?(v)
          }

          define_method("#{name}=") { |value|
            dereference.instance_variable_set("@#{name}", value)
          }
        }
      end

      def dereferencing_attr_accessor(*symbols)
        symbols.each { |name|
          define_method(name) {
            dereference.attributes[name.to_s]
          }

          define_method("#{name}=") { |value|
            dereference.attributes[name.to_s] = value
          }
        }
      end

      def has_required_or_attributes(names, var)
        names.each { |name|
          var << name

          @index_attribute ||= name.to_s

          if name == :href
            attr_accessor name
          else
            dereferencing_attr_accessor name
          end
        }
      end

      def has_attributes(*names)
        has_required_or_attributes(names, @attributes)
      end

      def has_required(*names)
        has_required_or_attributes(names, @required_attributes)
      end

      def may_be_reference
        @may_be_reference = true

        define_method(:dereference) {
          return self unless attributes['href']

          unless @referenced
            if attributes['href']
              find_method_name = "find_#{self.class.names[:element]}"

              p = self

              until @referenced || !p
                begin
                  p = p.parent
                end until !p || p.respond_to?(find_method_name)

                @referenced = p.send(find_method_name, attributes['href'], nil, false) if p
              end
            end
          end

          dereference_with_context(@referenced) if @referenced
        }
      end

      # Turn an XML element into an instance of this class.
      def from_element(parent, element, need_finalization)
        attributes = element.attributes

        me = new
        me.parent = parent

        @collections.each { |name, klass|
          me.instance_variable_set("@#{klass.names[:collection]}", [])
        }

        if @may_be_reference and href = attributes['href']
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

    end

    # Common instance methods

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
    def name_matches(name)
      index_key == name
    end

    def to_s(indent = 0)
      klass = self.class

      i = ' ' * indent
      s = "#{i}#{klass.name}\n"

      if klass.may_be_reference? and href = attributes['href']
        s << "#{i} href=#{href}\n"
      else
        [klass.required_attributes, klass.attributes].each { |list|
          list.each { |attr|
            val = attributes[attr.to_s]
            s << "#{i} #{attr}=#{val}\n" if val
          }
        }

        klass.members.each_value { |member_class|
          o = send(member_class.names[:member])
          s << o.to_s(indent + 1) if o
        }

        klass.collections.each_value { |collection_class|
          c = send(collection_class.names[:collection])

          if c && !c.empty?
            s << "#{i} Collection of #{c.size} #{collection_class.name}(s)\n"
            c.each { |o| s << o.to_s(indent + 2) }
          end
        }

        if @contents && !@contents.empty?
          sep = '-' * 80
          s << "#{sep}\n#{@contents.join(' ')}\n#{sep}\n"
        end
      end

      s
    end

  end

  #########################################################################
  # Classes to keep track of the logical structure of a URI.
  URIParts = Struct.new(:uri, :query, :headers) do

    def to_s
      u = uri.dup
      u << (uri.include?('?') ? '&' : '?') << query_string unless query.empty?
      u
    end

    alias_method :to_str, :to_s

    def inspect
      s = to_s
      s << " Plus headers: #{headers.inspect}" if headers
      s
    end

    def query_string
      query.join('&')
    end

    def hash(x)
      to_str.hash
    end

    def ==(x)
      x.respond_to?(:to_str) ? to_str == x : super
    end

  end

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
    end

    def _deep_copy_hash(h)
      h.inject({}) { |h, kv| h[kv[0]] = kv[1] && kv[1].dup; h }
    end

    def _deep_copy_array(a)
      a.inject([]) { |a, e| a << (e && e.dup) }
    end

    # Perform a deep copy.
    def deep_copy
      Address.new(
        _deep_copy_array(@path_fragments),
        _deep_copy_array(@query_vars),
        _deep_copy_hash(@headers),
        @path_params.dup,
        @query_params.dup,
        @header_params.dup
      )
    end

    def to_s
      "Address:\n"                                            <<
      " Path fragments: #{@path_fragments.inspect}\n"         <<
      " Query variables: #{@query_vars.inspect}\n"            <<
      " Header variables: #{@headers.inspect}\n"              <<
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

      # Bind variables found in the path fragments.
      path_params_to_delete = []

      path_fragments.each { |fragment|
        if fragment.respond_to?(:to_str)
          # This fragment is a string which might contain {} substitutions.
          # Make any substitutions available to the provided path variables.
          self.class.embedded_param_names(fragment).each { |param_name|
            value = path_var_values[param_name] || path_var_values[param_name.to_sym]

            value = if param = path_params[param_name]
              path_params_to_delete << param
              param % value
            else
              Param.default.format(value, param_name)
            end

            fragment.gsub!("{#{param_name}}", value)
          }
        else
          # This fragment is an array of Param objects (style 'matrix'
          # or 'plain') which may be bound to strings. As substitutions
          # happen, the array will become a mixed array of Param objects
          # and strings.
          fragment.each_with_index { |param, i|
            if param.respond_to?(:name)
              name = param.name

              value = path_var_values[name] || path_var_values[name.to_sym]
              value = param % value
              fragment[i] = value if value

              path_params_to_delete << param
            end
          }
        end
      }

      # Delete any embedded path parameters that are now bound from
      # our list of unbound parameters.
      path_params_to_delete.each { |p| path_params.delete(p.name) }

      # Bind query variable values to query parameters
      query_var_values.each { |name, value|
        if param = query_params[name.to_s]
          query_vars << param % value
          query_params.delete(name.to_s)
        end
      }

      # Bind header variables to header parameters
      header_var_values.each { |name, value|
        if param = header_params[name.to_s]
          headers[name] = param % value
          header_params.delete(name.to_s)
        end
      }

      self
    end

    def uri(args = {})
      obj = deep_copy
      obj.bind!(args)

      # Build the path
      uri = ''

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
        elsif fragment.required
          # This is a required Param that was never bound to a value.
          raise ArgumentError, %Q{Missing a value for required path parameter "#{fragment.name}"!}
        end
      }

      # Hunt for required unbound query parameters.
      obj.query_params.each { |name, value|
        if value.required
          raise ArgumentError, %Q{Missing a value for required query parameter "#{value.name}"!}
        end
      }

      # Hunt for required unbound header parameters.
      obj.header_params.each { |name, value|
        if value.required
          raise ArgumentError, %Q{Missing a value for required header parameter "#{value.name}"!}
        end
      }

      URIParts.new(uri, obj.query_vars, obj.headers)
    end

  end

  #########################################################################
  #
  # Now we use Ruby classes to define the structure of a WADL document
  class Documentation < CheapSchema

    in_document 'doc'
    has_attributes 'xml:lang', :title
    contents_are_mixed_data

  end

  class HasDocs < CheapSchema

    has_many Documentation

    # Convenience method to define a no-argument singleton method on
    # this object.
    def define_singleton(name, contents)
      instance_eval(%Q{def #{name}\n#{contents}\nend}) unless name =~ /\W/ || respond_to?(name)
    end

  end

  class Option < HasDocs

    in_document 'option'
    has_required :value

  end

  class Link < HasDocs

    in_document 'link'
    has_attributes :href, :rel, :rev

  end

  class Param < HasDocs

    in_document 'param'
    has_required :name
    has_attributes :type, :default, :style, :path, :required, :repeating, :fixed
    has_many Option, Link

    # A default Param object to use for a path parameter that is
    # only specified as a name in the path of a resource.
    def self.default
      @default ||= begin
        default = Param.new

        default.required = true
        default.style    = 'plain'
        default.type     = 'xsd:string'

        default
      end
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
        if required =~ /\A(?:true|1)\z/
          raise ArgumentError, %Q{No value provided for required param "#{name}"!}
        else
          return '' # No value provided and none required.
        end
      end

      if value.respond_to?(:each) && !value.respond_to?(:to_str)
        if repeating
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
        parent.respond_to?('is_form_representation?') && parent.is_form_representation?
      )
        values.map { |v| URI.escape(name) + '=' + URI.escape(v.to_s) }.join('&')
      elsif style == 'matrix'
        if type == 'xsd:boolean'
          values.map { |v| (v == 'true' || v == true) ? ';' + name : '' }.join
        else
          values.map { |v| v ? ';' + URI.escape(name) + '=' + URI.escape(v.to_s) : '' }.join
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

  # A mixin for objects that contain representations
  module RepresentationContainer

    def find_representation_by_media_type(type)
      representations.find { |r| r.mediaType == type }
    end

    def find_form
      representations.find { |r| r.is_form_representation? }
    end

  end

  class RepresentationFormat < HasDocs

    in_document 'representation'
    has_attributes :id, :mediaType, :element
    has_many Param
    may_be_reference

    def is_form_representation?
      mediaType == 'application/x-www-form-encoded' || mediaType == 'multipart/form-data'
    end

    # Creates a representation by plugging a set of parameters
    # into a representation format.
    def %(values)
      unless mediaType == 'application/x-www-form-encoded'
        raise "wadl.rb can't instantiate a representation of type #{mediaType}"
      end

      representation = []

      params.each { |param|
        name = param.name

        if param.fixed
          p_values = [param.fixed]
        elsif values[name] || values[name.to_sym]
          p_values = values[name] || values[name.to_sym]

          if !param.repeating || !(p_values.respond_to?(:each) && !p_values.respond_to?(:to_str))
            p_values = [p_values]
          end
        else
          if param.required
            raise ArgumentError, "Your proposed representation is missing a value for #{param.name}"
          end
        end

        if p_values
          p_values.each { |v| representation << CGI::escape(name) + '=' + CGI::escape(v.to_s) }
        end
      }

      representation.join('&')
    end

  end

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

      unless me.attributes['href']
        if name = me.attributes['id']
          begin
            c = Class.new(Fault)
            WADL::Faults.const_set(name, c) unless WADL::Faults.const_defined?(name)
            me.subclass = c
          rescue NameError
            # This fault format's ID can't be a class name. Use the
            # generic subclass of Fault.
          end
        end

        me.subclass ||= Fault
      end

      me
    end

  end

  class RequestFormat < HasDocs

    include RepresentationContainer

    in_document 'request'
    has_many RepresentationFormat, Param

    # Returns a URI and a set of HTTP headers for this request.
    def uri(resource, args = {})
      uri = resource.uri(args)

      query_values  = args[:query]   || {}
      header_values = args[:headers] || {}

      params.each { |param|
        name = param.name

        if param.style == 'header'
          value = header_values[name] || header_values[name.to_sym]
          value = param % value

          uri.headers[name] = value if value
        else
          value = query_values[name] || query_values[name.to_sym]
          value = param.format(value, nil, 'query')

          uri.query << value if value
        end
      }

      uri
    end

  end

  class ResponseFormat < HasDocs

    include RepresentationContainer

    in_document 'response'
    has_many RepresentationFormat, FaultFormat

    # Builds a service response object out of an HTTPResponse object.
    def build(http_response)
      # Figure out which fault or representation to use.

      status = http_response.status[0]

      unless response_format = faults.find { |f| f.dereference.status == status }
        # Try to match the response to a response format using a media
        # type.
        response_media_type = http_response.content_type
        response_format = representations.find { |f|
          t = f.dereference.mediaType
          t && response_media_type.index(t) == 0
        }

        # If an exact media type match fails, use the mime-types gem to
        # match the response to a response format using the underlying
        # subtype. This will match "application/xml" with "text/xml".
        unless response_format || !defined?(MIME::Types)
          mime_type = MIME::Types[response_media_type]
          raw_sub_type = mime_type[0].raw_sub_type if mime_type && !mime_type.empty?

          response_format = representations.find { |f|
            if t = f.dereference.mediaType
              response_mime_type = MIME::Types[t]
              response_raw_sub_type = response_mime_type[0].raw_sub_type if response_mime_type && !response_mime_type.empty?
              response_raw_sub_type == raw_sub_type
            end
          }
        end

        # If all else fails, try to find a response that specifies no
        # media type. TODO: check if this would be valid WADL.
        response_format ||= representations.find { |f| !f.dereference.mediaType }
      end

      body = http_response.read

      if response_format && response_format.mediaType =~ /xml/
        begin
          body = REXML::Document.new(body)

          # Find the appropriate element of the document
          if response_format.element
            # TODO: don't strip the damn namespace. I'm not very good at
            # namespaces and I don't see how to deal with them here.
            element = response_format.element.sub(/.*:/, '')
            body = REXML::XPath.first(body, "//#{element}")
          end
        rescue REXML::ParseException
        end

        body.extend(XMLRepresentation)
        body.representation_of(response_format)
      end

      klass = response_format.is_a?(FaultFormat) ? response_format.subclass : Response
      obj = klass.new(http_response.status, http_response, body, response_format)

      obj.is_a?(Exception) ? raise(obj) : obj
    end

  end

  class HTTPMethod < HasDocs

    in_document 'method'
    as_collection 'http_methods'
    has_required :id, :name
    has_one RequestFormat, ResponseFormat
    may_be_reference

    # Args:
    #  :path - Values for path parameters
    #  :query - Values for query parameters
    #  :headers - Values for header parameters
    #  :send_representation
    #  :expect_representation
    def call(resource, args = {})
      unless parent.respond_to?(:uri)
        raise "You can't call a method that's not attached to a resource! (You may have dereferenced a method when you shouldn't have)"
      end

      resource ||= parent
      method = dereference

      uri = method.request ? method.request.uri(resource, args) : resource.uri(args)
      headers = uri.headers.dup

      headers['Accept']       = expect_representation.mediaType if args[:expect_representation]
      headers['User-Agent']   = 'Ruby WADL client' unless headers['User-Agent']
      headers['Content-Type'] = 'application/x-www-form-urlencoded'
      headers[:method]        = name.downcase.to_sym
      headers[:body]          = args[:send_representation]

      begin
        response = open(uri, headers)
      rescue OpenURI::HTTPError => err
        response = err.io
      end

      method.response.build(response)
    end

  end

  # A mixin for objects that contain resources. If you include this, be
  # sure to alias :find_resource to :find_resource_autogenerated
  # beforehand.
  module ResourceContainer

    def resource(name_or_id)
      name_or_id = name_or_id.to_s
      find_resource(nil, lambda { |r| r.id == name_or_id || r.path == name_or_id })
    end

    def find_resource_by_path(path, *args)
      path = path.to_s
      find_resource(nil, lambda { |r| r.path == path }, *args)
    end

    def finalize_creation
      resources.each { |r|
        define_singleton(r.id, "find_resource('#{r.id}')") if r.id && !r.respond_to?(r.id)
        define_singleton(r.path, "find_resource_by_path('#{r.path}')") if r.path && !r.respond_to?(r.path)
      } if resources
    end

  end

  # A type of resource. Basically a mixin of methods and params for actual
  # resources.
  class ResourceType < HasDocs

    in_document 'resource_type'
    has_attributes :id
    has_many HTTPMethod, Param

  end

  class Resource < HasDocs

    include ResourceContainer

    in_document 'resource'
    has_attributes :id, :path
    has_many Resource, HTTPMethod, Param, ResourceType

    def initialize(*args)
      super
    end

    def dereference_with_context(child)
      ResourceAndAddress.new(child, parent.address)
    end

    # Returns a ResourceAndAddress object bound to this resource
    # and the given query variables.
    def bind(args = {})
      resource = ResourceAndAddress.new(self)
      resource.bind!(args)
      resource
    end

    # Sets basic auth parameters
    def with_basic_auth(user, pass, param_name = 'Authorization')
      bind(:headers => { param_name => "Basic #{["#{user}:#{pass}"].pack('m')}" })
    end

    def uri(args = {}, working_address = nil)
      working_address &&= working_address.deep_copy
      address(working_address).uri(args)
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

    def get(*args, &block)
      find_method_by_http_method('get').call(self, *args, &block)
    end

    def post(*args, &block)
      find_method_by_http_method('post').call(self, *args, &block)
    end

    def put(*args, &block)
      find_method_by_http_method('put').call(self, *args, &block)
    end

    def delete(*args, &block)
      find_method_by_http_method('delete').call(self, *args, &block)
    end

  end

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
      resource ? ResourceAndAddress.new(resource, @address) : resource
    end

    def find_resource(*args, &block)
      resource = @resource.find_resource(*args, &block)
      resource ? ResourceAndAddress.new(resource, @address) : resource
    end

    def find_resource_by_path(*args, &block)
      resource = @resource.find_resource_by_path(*args, &block)
      resource ? ResourceAndAddress.new(resource, @address) : resource
    end

    def get(*args, &block)
      find_method_by_http_method('get').call(self, *args, &block)
    end

    def post(*args, &block)
      find_method_by_http_method('post').call(self, *args, &block)
    end

    def put(*args, &block)
      find_method_by_http_method('put').call(self, *args, &block)
    end

    def delete(*args, &block)
      find_method_by_http_method('delete').call(self, *args, &block)
    end

  end

  class Resources < HasDocs

    include ResourceContainer

    in_document 'resources'
    as_member 'resource_list'
    has_attributes :base
    has_many Resource

  end

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
      return unless resource_list

      resource_list.resources.each { |r|
        define_singleton(r.id, "resource_list.find_resource('#{r.id}')") if r.id && !r.respond_to?(r.id)
        define_singleton(r.path, "resource_list.find_resource_by_path('#{r.path}')") if r.path && !r.respond_to?(r.path)
      }
    end

  end

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

  Response = Struct.new(:code, :headers, :representation, :format)

  class Fault < Exception

    attr_accessor :code, :headers, :representation, :format

    def initialize(code, headers, representation, format)
      @code, @headers, @representation, @format = code, headers, representation, format
    end

  end

end
