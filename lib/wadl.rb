# wadl.rb
# http://www.crummy.com/software/wadl.rb/
# Super cheap Ruby WADL client
# by Leonard Richardson leonardr@segfault.org
# v20070217
# For more on WADL, see http://wadl.dev.java.net/

require 'rubygems'
require 'rest-open-uri'

require 'delegate'
require 'rexml/document'
require 'set'
require 'cgi'

begin
  require 'rubygems'
  require 'mime/types'
  MIME_TYPES_SUPPORTED = true
rescue LoadError
  MIME_TYPES_SUPPORTED = false
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

  attr_accessor :index_key, :href

  @may_be_reference = false
  @contents_are_mixed_data = false

  def initialize
    @attributes = {}
    @contents = nil
  end

  def self.init
    @names = {}

    @members = {}
    @collections = {}
    @required_attributes = []
    @attributes = []
  end

  def self.inherit(from)
    init
    @names = from.names.dup if from.names
    @members = from.members.dup if from.members
    @collections = from.collections.dup if from.collections
    @required_attributes = from.required_attributes.dup if from.required_attributes
    @attributes = from.attributes.dup if from.attributes
  end

  def self.inherited(klass)    
    klass.inherit(self)
  end

  def self.names
    @names
  end

  def self.members
    @members
  end

  def self.collections
    @collections
  end

  def self.required_attributes
    @required_attributes
  end

  def self.attributes
    @attributes
  end

  def attributes
    @attributes
  end

  def self.may_be_reference?
    @may_be_reference
  end

  def self.in_document(element_name)
    @names[:element] = element_name
    @names[:member] = element_name
    @names[:collection] = element_name + 's'
  end

  def self.as_collection(collection_name)
    @names[:collection] = collection_name
  end

  def self.as_member(member_name)
    @names[:member] = member_name
  end

  def self.contents_are_mixed_data
    @contents_are_mixed_data = true
  end

  def self.has_one(*classes)
    classes.each do |c| 
      @members[c.names[:element]] = c
      member_name = c.names[:member]
      dereferencing_instance_accessor member_name
    end
  end

  def self.has_many(*classes)
    classes.each do |c| 
      @collections[c.names[:element]] = c
      collection_name = c.names[:collection]
      dereferencing_instance_accessor collection_name
      find_method_name = "find_#{c.names[:element]}"      

      # Define a method for finding a specific element of this
      # collection.
      # TODO: In Ruby 1.9, make match_block a block argument.
      define_method(find_method_name) do |name, *args|
        name = name.to_s

        if args[0].respond_to? :call
          match_block = args[0]
        else
          match_block = Proc.new { |m| m.name_matches(name) }
        end

        unless args[1].nil?
          auto_dereference = args[1]
        else
          auto_dereference = true
        end

        match = self.send(collection_name).detect do |m|
          match_block.call(m) || \
          (c.may_be_reference? && auto_dereference && 
           match_block.call(m.dereference))
        end
        match = match.dereference if match && auto_dereference
        return match
      end
    end
  end

  def self.dereferencing_instance_accessor(*symbols)
    symbols.each do |name|
      define_method(name) do 
        dereference.instance_variable_get("@#{name}")
      end
      define_method(name.to_s+'=') do |value|
        dereference.instance_variable_set("@#{name}", value)
      end
    end
  end

  def self.dereferencing_attr_accessor(*symbols)
    symbols.each do |name|
      m = instance_methods
      define_method(name) do 
        dereference.attributes[name.to_s]
      end
      define_method(name.to_s+'=') do |value|
        dereference.attributes[name.to_s] = value
      end
    end
  end
  
  def self.has_attributes(*names)
    names.each do |name|
      @attributes << name
      @index_attribute ||= name.to_s
      if name == :href
        attr_accessor name
      else
        dereferencing_attr_accessor name
      end
    end
  end

  def self.has_required(*names)
    names.each do |name|
      @required_attributes << name
      @index_attribute ||= name.to_s
      if name == :href
        attr_accessor name
      else
        dereferencing_attr_accessor name
      end
    end
  end

  def self.may_be_reference
    @may_be_reference = true
    define_method("dereference") do
      return self if not self.attributes['href']
      unless @referenced       
        if self.attributes['href']
          find_method_name = "find_#{self.class.names[:element]}"          
          p = self
          until @referenced or !p do
            begin
              p = p.parent
            end until !p or p.respond_to? find_method_name
            if p
              @referenced = p.send(find_method_name, self.attributes['href'], nil, false) if p
            else
              @referenced = nil
            end
          end
        end
      end
      @referenced ? dereference_with_context(@referenced) : nil
    end
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

  # Turn an XML element into an instance of this class.
  def self.from_element(parent, e, need_finalization)
    attributes = e.attributes
    me = self.new
    me.parent = parent
    
    @collections.each do |name, clazz|
      collection_name = "@" + clazz.names[:collection].to_s
      me.instance_variable_set(collection_name, [])
    end
      
    if @may_be_reference and attributes['href']
      # Handle objects that are just references to other objects
      # somewhere above this one in the hierarchy
      href = attributes['href']
      if href[0] == ?#
        href = href[1..href.size]
      else
        puts "Warning: HREF #{href} should be ##{href}"
      end
      me.attributes['href'] = href

    else
      # Handle this element's attributes
      @required_attributes.each do |name|
        name = name.to_s
        unless attributes[name]
          raise ArgumentError, %{Missing required attribute "#{name}" in element: #{e}}
        end
        #puts " #{name}=#{attributes[name]}"
        me.attributes[name.to_s] = attributes[name]
        me.index_key = attributes[name] if name == @index_attribute
      end
      
      @attributes.each do |name|
        name = name.to_s
        #puts " #{name}=#{attributes[name]}"
        me.attributes[name.to_s] = attributes[name]
        me.index_key = attributes[name] if name == @index_attribute
      end      
    end

    # Handle this element's children.
    if @contents_are_mixed_data
      me.instance_variable_set('@contents', e.children)
    else
      e.each_element do |child|
        clazz = @members[child.name] || @collections[child.name]
        if clazz        
          object = clazz.from_element(me, child, need_finalization)
          if clazz == @members[child.name]
            #puts "#{self.name} can have one #{clazz.name}"
            instance_variable_name = "@" + clazz.names[:member].to_s
            if me.instance_variable_get(instance_variable_name)
              raise "#{self.name} can only have one #{clazz.name}, but several were specified in element: #{e}"
            end          
            #puts "Setting its #{instance_variable_name} to a #{object.class.name}"
            me.instance_variable_set(instance_variable_name, object)
          else
            #puts "#{self.name} can have many #{clazz.name}"
            collection_name = "@" + clazz.names[:collection].to_s
            collection = me.instance_variable_get(collection_name)
            #puts "Adding a #{object.class.name} to #{collection_name} collection"
            collection << object
          end
        end
      end
    end
    need_finalization << me if me.respond_to? :finalize_creation
    return me
  end

  # Common instance methods
  
  attr_accessor :parent

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

  def to_s(indent=0)
    s = ""
    i = " " * indent 
    s << "#{i}#{self.class.name}\n"
    if self.class.may_be_reference? and self.attributes['href']
      s << "#{i} href=#{self.attributes['href']}\n"
    else
      [self.class.required_attributes, self.class.attributes].each do |list|
        list.each do |attr| 
          attr = attr.to_s
          s << "#{i} #{attr}=#{self.attributes[attr]}\n" if self.attributes[attr]
        end
      end
      self.class.members.each_value do |member_class|
        o = self.send(member_class.names[:member])
        s << o.to_s(indent+1) if o
      end
      self.class.collections.each_value do |collection_class|
        c = self.send(collection_class.names[:collection])
        if c and not c.empty?
          s << "#{i} Collection of #{c.size} #{collection_class.name}(s)\n"
          c.each do |o|
            s << o.to_s(indent+2)
          end
        end
      end
      if @contents && !@contents.empty?
        s << '-' * 80 << "\n" << @contents.join(' ') << "\n" << '-' * 80 << "\n"
      end
    end
    return s
  end
end

#########################################################################
# Classes to keep track of the logical structure of a URI.

URIParts = Struct.new(:uri, :query, :headers)
class URIParts

  def to_s
    u = uri.dup
    unless query.empty? 
      u << (uri.index('?') ? '&' : '?')
      u << query_string
    end
    u
  end

  def inspect
    s = to_s 
    s << " Plus headers: #{headers.inspect}" if headers
  end

  def query_string
    query.join('&')
  end

  def hash(x)
    to_str.hash
  end

  def ==(x)
    return to_str == x if x.respond_to? :to_str
    return super
  end

  alias :to_str :to_s
end

# The Address class keeps track of the user's path through a resource
# graph. Values for WADL parameters may be specified at any time using
# the bind method. An Address cannot be turned into a URI and header
# set until all required parameters have been bound to values.
#
# An Address object is built up through calls to Resource#address
class Address
  attr_reader :path_fragments, :query_vars, :headers, \
              :path_params, :query_params, :header_params

  def initialize(path_fragments=[], query_vars=[], headers={},
                 path_params={}, query_params={}, header_params={})
    @path_fragments = path_fragments
    @query_vars, @headers = query_vars, headers

    @path_params, @query_params, @header_params = path_params, query_params, header_params
  end

  def _deep_copy_hash(h)
    a = h.inject({}) { |h,kv| h[kv[0]] = (kv[1] ? kv[1].dup : kv[1]); h }
  end

  def _deep_copy_array(a)
    a.inject([]) { |a,e| a << (e ? e.dup : e) }
  end

  # Perform a deep copy.
  def deep_copy
    Address.new(_deep_copy_array(@path_fragments),
                _deep_copy_array(@query_vars), _deep_copy_hash(@headers),
                @path_params.dup, @query_params.dup,
                @header_params.dup)
  end

  def to_s
    s = "Address:\n"
    s << " Path fragments: #{@path_fragments.inspect}\n"
    s << " Query variables: #{@query_vars.inspect}\n"
    s << " Header variables: #{@headers.inspect}\n"
    s << " Unbound path parameters: #{@path_params.inspect}\n"
    s << " Unbound query parameters: #{@query_params.inspect}\n"
    s << " Unbound header parameters: #{@header_params.inspect}\n"
  end

  alias :inspect :to_s

  def self.embedded_param_names(fragment)
    fragment.scan(/\{([^}]+)\}/).flatten
  end

  # Binds some or all of the unbound variables in this address to values.
  def bind!(args={})
    path_var_values = args[:path] || {}
    query_var_values = args[:query] || {}
    header_var_values = args[:headers] || {}
    # Bind variables found in the path fragments.
    if path_var_values
      path_params_to_delete = []
      path_fragments.each do |fragment|
        if fragment.respond_to? :to_str
          # This fragment is a string which might contain {} substitutions.
          # Make any substitutions available to the provided path variables.
          embedded_param_names = self.class.embedded_param_names(fragment)
          embedded_param_names.each do |param_name|
            value = path_var_values[param_name] || path_var_values[param_name.to_sym]
            param = path_params[param_name]
            if param
              value = param % value
              path_params_to_delete << param
            else
              value = Param.default.%(value, param_name)
            end
            fragment.gsub!('{' + param_name + '}', value)
          end
        else
          # This fragment is an array of Param objects (style 'matrix'
          # or 'plain') which may be bound to strings. As substitutions
          # happen, the array will become a mixed array of Param objects
          # and strings.
          fragment.each_with_index do |param, i|
            if param.respond_to? :name
              value = path_var_values[param.name] || path_var_values[param.name.to_sym]
              new_value = param % value           
              fragment[i] = new_value if new_value
              path_params_to_delete << param
            end
          end
        end
      end

      # Delete any embedded path parameters that are now bound from
      # our list of unbound parameters.
      path_params_to_delete.each { |p| path_params.delete(p.name) }      
    end

    # Bind query variable values to query parameters
    query_var_values.each do |name, value|
      param = query_params[name.to_s]
      if param
        query_vars << param % value
        query_params.delete(name.to_s)
      end
    end

    # Bind header variables to header parameters
    header_var_values.each do |name, value|
      param = header_params[name.to_s]
      if param
        headers[name] = param % value
        header_params.delete(name.to_s)
      end
    end
    return self
  end

  def uri(args={})
    obj = deep_copy
    obj.bind!(args) 

    # Build the path
    uri = ''
    obj.path_fragments.flatten.each do |fragment|
      if fragment.respond_to? :to_str
        embedded_param_names = self.class.embedded_param_names(fragment)
        unless embedded_param_names.empty?
          raise ArgumentError, %{Missing a value for required path parameter "#{embedded_param_names[0]}"!}
        end
        unless fragment.empty?
          uri << '/' if !uri.empty? && uri[-1] != ?/
          uri << fragment
        end
      elsif fragment.required
        # This is a required Param that was never bound to a value.
        raise ArgumentError, %{Missing a value for required path parameter "#{fragment.name}"!}
      end
    end
  
    # Hunt for required unbound query parameters.
    obj.query_params.each do |name, value|
      if value.required
        raise ArgumentError, %{Missing a value for required query parameter "#{value.name}"!}
      end
    end

    # Hunt for required unbound header parameters.
    obj.header_params.each do |name, value|
      if value.required
        raise ArgumentError, %{Missing a value for required header parameter "#{value.name}"!}
      end
    end

    return URIParts.new(uri, obj.query_vars, obj.headers)
  end

end

#########################################################################
#
# Now we use Ruby classes to define the structure of a WADL document

class Documentation < CheapSchema
  in_document 'doc'
  as_member 'doc'
  as_collection 'docs'

  has_attributes "xml:lang", :title
  contents_are_mixed_data
end

class HasDocs < CheapSchema
  has_many Documentation

  # Convenience method to define a no-argument singleton method on
  # this object.
  def define_singleton(name, contents)
    return if name =~ /[^A-Za-z0-9_]/
    instance_eval(%{def #{name}
                      #{contents}
                    end})
  end
end

class Option < HasDocs
  in_document 'option'
  as_member 'option'
  as_collection 'options'
  has_required :value
end

class Link < HasDocs
  in_document 'link'
  as_member 'link'
  as_collection 'links'
  has_attributes :href, :rel, :rev
end

class Param < HasDocs
  in_document 'param' 
  as_member 'param'
  as_collection 'params'
  has_required :name
  has_attributes :type, :default, :style, :path, :required, :repeating, :fixed
  has_many Option
  has_many Link

  def inspect
    %{Param "#{name}"}
  end

  # Validates and formats a proposed value for this parameter. Returns
  # the formatted value. Raises an ArgumentError if the value
  # is invalid.
  #
  # The 'name' and 'style' arguments are used in conjunction with the
  # default Param object.
  def %(value, name=nil, style=nil)
    name ||= self.name
    style ||= self.style
    value = fixed if fixed
    unless value 
      if default
        value = default
      elsif required
        raise ArgumentError, "No value provided for required param \"#{name}\"!"
      else
        return '' # No value provided and none required.
      end
    end

    if value.respond_to?(:each) && !value.respond_to?(:to_str)
      if repeating
        values = value
      else
        raise ArgumentError, "Multiple values provided for single-value param \"#{name}\""
      end
    else
      values = [value]
    end
      
    # If the param lists acceptable values in option tags, make sure that
    # all values are found in those tags.
    if options && !options.empty?
      values.each do |value|
        unless find_option(value)
          acceptable = options.collect { |o| o.value }.join('", "')
            raise ArgumentError, %{"#{value}" is not among the acceptable parameter values ("#{acceptable}")}
        end
      end
    end

    if style == 'query' || parent.is_a?(RequestFormat) ||
        (parent.respond_to?('is_form_representation?') \
          && parent.is_form_representation?)
      value = values.collect do |v|
        URI.escape(name) + '=' + URI.escape(v.to_s)
      end.join('&')
    elsif self.style == 'matrix'      
      if type == 'xsd:boolean'
        value = values.collect { |v| (v == 'true' || v == true) ? ';' + name : '' }.join('')
      else
        value = values.collect do |v|
          v ? ';' + URI.escape(name) + '=' + URI.escape(v.to_s) : ''
        end.join('')
      end
    elsif self.style == 'header'
      value = values.join(',')
    else
      # All other cases: plain text representation.
      value = values.collect { |v| URI.escape(v.to_s) }.join(',')
    end
    return value
  end


  # A default Param object to use for a path parameter that is
  # only specified as a name in the path of a resource.
  @@default = Param.new
  @@default.required = true
  @@default.style = 'plain'
  @@default.type = 'xsd:string'

  def self.default
    @@default
  end
end

# A mixin for objects that contain representations
module RepresentationContainer
  def find_representation_by_media_type(type)
    representations.detect { |r| r.mediaType == type }
  end

  def find_form
    representations.detect { |r| r.is_form_representation? }
  end
end

class RepresentationFormat < HasDocs
  in_document 'representation'
  as_collection 'representations'
  may_be_reference
  has_attributes :id, :mediaType, :element
  has_many Param 

  def is_form_representation?
    return mediaType == 'application/x-www-form-encoded' ||
      mediaType == 'multipart/form-data'
  end

  # Creates a representation by plugging a set of parameters 
  # into a representation format.
  def %(values)
    if mediaType == 'application/x-www-form-encoded'
      representation = []
      params.each do |param|
        if param.fixed
          p_values = [param.fixed]
        elsif values[param.name] || values[param.name.to_sym]
          p_values = values[param.name] || values[param.name.to_sym]
          if !param.repeating || !(p_values.respond_to?(:each) && !p_values.respond_to?(:to_str))
            p_values = [p_values]
          end
        else
          if param.required
            raise ArgumentError,  "Your proposed representation is missing a value for #{param.name}"
          end
        end
        if p_values
          p_values.each do |value|
            representation << CGI::escape(param.name) + '=' + CGI::escape(value.to_s)
          end
        end
      end
      representation = representation.join('&')
    else
      raise Exception,
      "wadl.rb can't instantiate a representation of type #{mediaType}"
    end
    return representation
  end
end

class FaultFormat < RepresentationFormat
  in_document 'fault'
  as_collection 'faults'
  may_be_reference
  has_attributes :id, :mediaType, :element, :status
  has_many Param

  attr_writer :subclass

  def subclass
    if attributes['href']
      dereference.subclass
    else
      @subclass
    end
  end

  # Define a custom subclass for this fault, so that the programmer
  # can rescue this particular fault.
  def self.from_element(*args)
    me = super
    return me if me.attributes['href']
    name = me.attributes['id']
    if name
      begin
        c = Class.new(Fault)
        WADL::Faults.const_set(name, c) unless WADL::Faults.const_defined? name
        me.subclass = c
      rescue NameError => e
        # This fault format's ID can't be a class name. Use the
        # generic subclass of Fault.
      end
    end
    me.subclass ||= Fault
    return me
  end
end

class RequestFormat < HasDocs
  include RepresentationContainer
  in_document 'request'
  has_many RepresentationFormat
  has_many Param

  # Returns a URI and a set of HTTP headers for this request.
  def uri(resource, args={})
    uri = resource.uri(args)
    query_values = args[:query] || {}
    header_values = args[:headers] || {}
    params.each do |param|
      if param.style == 'header'
        value = header_values[param.name] || header_values[param.name.to_sym]
        value = param % value
        uri.headers[param.name] = value if value
      else        
        value = query_values[param.name] || query_values[param.name.to_sym]
        value = param.%(value, nil, 'query')
        uri.query << value if value
      end
    end
    return uri
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
    response_format = self.faults.detect do |f| 
      f.dereference.status == status
    end

    unless response_format
      # Try to match the response to a response format using a media
      # type.      
      response_media_type = http_response.content_type
      response_format = representations.detect do |f|
        t = f.dereference.mediaType
        t && response_media_type.index(t) == 0
      end      

      # If an exact media type match fails, use the mime-types gem to
      # match the response to a response format using the underlying
      # subtype. This will match "application/xml" with "text/xml".
      if !response_format && MIME_TYPES_SUPPORTED
        mime_type = MIME::Types[response_media_type]
        raw_sub_type = mime_type[0].raw_sub_type if mime_type
        response_format = representations.detect do |f|
          t = f.dereference.mediaType
          if t
            response_mime_type = MIME::Types[t]
            response_raw_sub_type = response_mime_type[0].raw_sub_type if response_mime_type
            response_raw_sub_type == raw_sub_type
          end
        end
      end

      # If all else fails, try to find a response that specifies no
      # media type. TODO: check if this would be valid WADL.
      if !response_format 
        response_format = representations.detect do |f| 
          !f.dereference.mediaType
        end
      end
    end

    body = http_response.read
    if response_format && response_format.mediaType =~ /xml/
      begin
        body = REXML::Document.new(body)
        # Find the appropriate element of the document
        if response_format.element
          #TODO: don't strip the damn namespace. I'm not very good at
          #namespaces and I don't see how to deal with them here.
          element = response_format.element.gsub(/.*:/, '')
          body = REXML::XPath.first(body, "//#{element}")
        end
      rescue REXML::ParseException        
      end
      body.extend(XMLRepresentation)
      body.representation_of(response_format)
    end

    clazz = response_format.is_a?(FaultFormat) ? response_format.subclass : Response
    obj = clazz.new(http_response.status, http_response, body, response_format)
    raise obj if obj.is_a? Exception
    return obj
  end
end

class HTTPMethod < HasDocs
  in_document 'method'
  as_collection 'http_methods'
  may_be_reference
  has_required :id, :name
  has_one RequestFormat
  has_one ResponseFormat

  # Args:
  #  :path - Values for path parameters
  #  :query - Values for query parameters
  #  :headers - Values for header parameters
  #  :send_representation
  #  :expect_representation
  def call(resource, args={})
    unless parent.respond_to? :uri
      raise Exception, \
      "You can't call a method that's not attached to a resource! (You may have dereferenced a method when you shouldn't have)" 
    end
    resource ||= parent

    method = self.dereference
    if method.request
      uri = method.request.uri(resource, args)
    else
      uri = resource.uri
    end
    headers = uri.headers.dup
    if args[:expect_representation]
      headers['Accept'] = expect_representation.mediaType
    end
    headers['User-Agent'] = 'Ruby WADL client' unless headers['User-Agent']
    headers[:method] = name.downcase.to_sym
    headers[:body] = args[:send_representation]

    #puts "#{headers[:method].to_s.upcase} #{uri}"
    #puts " Options: #{headers.inspect}"
    begin
      response = open(uri, headers)
    rescue OpenURI::HTTPError => e
      response = e.io
    end
    return method.response.build(response)
  end
end

# A mixin for objects that contain resources. If you include this, be
# sure to alias :find_resource to :find_resource_autogenerated
# beforehand.
module ResourceContainer
  def resource(name_or_id)
    name_or_id = name_or_id.to_s
    find_resource(nil, Proc.new do |r| 
                    r.id == name_or_id || r.path == name_or_id 
                  end)
  end

  def find_resource_by_path(path, *args)
    path = path.to_s
    match_predicate = Proc.new { |resource| resource.path == path }
    find_resource(nil, match_predicate, *args)
  end

  def finalize_creation
    return unless resources
    resources.each do |r|  
      if r.id && !r.respond_to?(r.id)
        define_singleton(r.id, "find_resource('#{r.id}')")
      end
    end

    resources.each do |r|  
      if r.path && !r.respond_to?(r.path)
        define_singleton(r.path, "find_resource_by_path('#{r.path}')")
      end
    end
  end
end

# A type of resource. Basically a mixin of methods and params for actual
# resources.
class ResourceType < HasDocs
  in_document 'resource_type'
  as_collection 'resource_types'
  has_many HTTPMethod
  has_many Param
  has_attributes :id
end

class Resource < HasDocs
  in_document 'resource'
  as_collection 'resources'
  has_many Resource
  has_many HTTPMethod
  has_many Param
  has_many ResourceType
  has_attributes :id, :path

  include ResourceContainer

  def initialize(*args)
    super(*args)
  end

  def dereference_with_context(child)
    ResourceAndAddress.new(child, parent.address)
  end
       
  # Returns a ResourceAndAddress object bound to this resource
  # and the given query variables.
  def bind(args={})
    resource = ResourceAndAddress.new(self)
    resource.bind!(args)
    return resource
  end

  # Sets basic auth parameters 
  def with_basic_auth(user, pass, param_name='Authorization')
    value = 'Basic ' + [user.to_s+':'+pass.to_s].pack('m')
    a = bind(:headers => {param_name => value })
  end

  def uri(args={}, working_address=nil)
    working_address = working_address.deep_copy if working_address
    address(working_address).uri(args)
  end

  # Returns an Address object refering to this resource
  def address(working_address=nil)
    if working_address
      working_address = working_address.deep_copy
    else
      if parent.respond_to? :base
        working_address = Address.new()
        working_address.path_fragments << parent.base
      else
        working_address = parent.address.deep_copy
      end
    end
    working_address.path_fragments << path.dup

    # Install path, query, and header parameters in the Address. These
    # may override existing parameters with the same names, but if
    # you've got a WADL application that works that way, you should
    # have bound parameters to values earlier.
    new_path_fragments = []
    embedded_param_names = Set.new(Address.embedded_param_names(path))
    params.each do |param|      
      if embedded_param_names.member? param.name
        working_address.path_params[param.name] = param
      else
        if param.style == 'query'
          working_address.query_params[param.name] = param
        elsif param.style == 'header'
          working_address.header_params[param.name] = param
        else
          new_path_fragments << param
          working_address.path_params[param.name] = param
        end
      end
    end
    working_address.path_fragments << new_path_fragments unless new_path_fragments.empty?
    return working_address
  end

  def representation_for(http_method, request=true, all=false)
    method = find_method_by_http_method(http_method)
    if request
      container = method.request
    else
      container = method.response
    end
    representations = container.representations
    unless all
      representations = representations[0]
    end
    return representations
  end

  def find_by_id(id)
    id = id.to_s
    resources.detect { |r| r.dereference.id == id }
  end

  # Find HTTP methods in this resource and in the mixed-in types
  def each_http_method
    http_methods.each { |m| yield m }
    resource_types.each do |t|
      t.http_methods.each { |m| yield m }
    end
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
  def initialize(resource, address=nil, combine_address_with_resource=true)
    @resource = resource
    if combine_address_with_resource
      @address = @resource.address(address)
    else
      @address = address
    end
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
    "ResourceAndAddress\n Resource: #{@resource.to_s}\n #{@address.inspect}"
  end

  def address
    @address
  end

  def bind(*args)
    ResourceAndAddress.new(@resource, @address.deep_copy, false).bind!(*args)
  end

  def bind!(args={})
    @address.bind!(args)
    self
  end

  def uri(args={})
    @address.deep_copy.bind!(args).uri
  end

  # method_missing is to catch generated methods that don't get delegated.
  def method_missing(name, *args, &block)
    if @resource.respond_to? name
      result = @resource.send(name, *args, &block)
      if result.is_a? Resource
        result = ResourceAndAddress.new(result, @address.dup)
      end
      return result
    else
      raise NoMethodError, "undefined method `#{name}' for #{self}:#{self.class}"
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
  in_document 'resources'
  as_member 'resource_list'
  has_many Resource
  has_attributes :base

  include ResourceContainer
end

class Application < HasDocs  
  in_document 'application'
  has_one Resources
  has_many HTTPMethod, RepresentationFormat, FaultFormat

  def Application.from_wadl(wadl)
    wadl = wadl.read if wadl.respond_to?(:read)
    doc = REXML::Document.new(wadl)    
    need_finalization = []
    application = from_element(nil, doc.root, need_finalization)
    need_finalization.each { |x| x.finalize_creation }
    return application
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
    resource_list.resources.each do |r|  
      if r.id && !r.respond_to?(r.id)
        define_singleton(r.id, "resource_list.find_resource('#{r.id}')")
      end
    end

    resource_list.resources.each do |r|  
      if r.path && !r.respond_to?(r.path)
        define_singleton(r.path, 
                         "resource_list.find_resource_by_path('#{r.path}')")
      end
    end
  end
end

# A module mixed in to REXML documents to make them representations in the
# WADL sense.
module XMLRepresentation
  def representation_of(format)
    @params = format.params
  end

  def lookup_param(name)
    p = @params.detect { |p| p.name = name }
    raise ArgumentError, "No such param #{name}" unless p
    raise ArgumentError, "Param #{name} has no path!" unless p.path
    return p
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
    self.code = code
    self.headers = headers
    self.representation = representation
    self.format = format    
  end
end

end # End WADL module
