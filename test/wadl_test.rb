# Unit tests for the Ruby WADL library.

begin
  require 'rubygems'
rescue LoadError
end

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'test/unit'
require 'wadl'

class WADLTest < Test::Unit::TestCase

  def wadl(wadl)
    WADL::Application.from_wadl(<<-EOT)
<?xml version="1.0"?>
<application xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://research.sun.com/wadl wadl.xsd"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema"
             xmlns="http://research.sun.com/wadl">
#{wadl}
</application>
    EOT
  end

  # Null test to shut the compiler up. (Ruby < 1.9)
  def test_null
  end

end

class FindingWhatYouNeed < WADLTest

  def setup
    @wadl = wadl(<<-EOT)
<resources base="http://www.example.com/">
  <resource id="green_things" path="green">
    <resource href="#frogs" />
    <resource id="pistachios" path="pistachio" />
    <method href="#fetch" />
  </resource>

  <resource id="hopping_things" path="hop">
    <resource href="#frogs" />
  </resource>

  <resource id="frogs" path="frog">
    <method name="POST" id="fetch_frog" />
  </resource>
</resources>

<method name="GET" id="fetch" />
    EOT
  end

  # Test the ability to find a resource by ID, to find a sub-resource
  # of a resource, and to dereference a resource.
  def test_find_resource_by_id
    green_things = @wadl.find_resource(:green_things)
    frogs = @wadl.find_resource(:frogs)

    assert_equal(green_things.id, 'green_things')
    assert_equal(frogs.path, 'frog')
    assert_equal(green_things.find_resource(:frogs), frogs)
    assert_equal(green_things.find_resource(:pistachios).path, "pistachio")
  end

  # Test the ability to find a resource by path.
  def test_find_resource_by_path
    green_things = @wadl.green
    assert_equal(green_things.id, 'green_things')

    green_things = @wadl.find_resource_by_path('green')
    assert_equal(green_things.id, 'green_things')

    green_things = @wadl.resource('green')
    assert_equal(green_things.id, 'green_things')

    frogs = green_things.find_resource_by_path('frog')
    assert_equal(frogs.id, 'frogs')
  end

  # Dereference a resource two different ways and construct two different
  # URIs from the same resource.
  def test_dereference_resource
    green_frogs = @wadl.green_things.frogs
    assert_equal(green_frogs.uri, 'http://www.example.com/green/frog')

    hopping_frogs = @wadl.hopping_things.frogs
    assert_equal(hopping_frogs.uri, 'http://www.example.com/hop/frog')
  end

  # Find a resource's method by id or HTTP action.
  def test_find_method
    frogs = @wadl.find_resource(:frogs)

    assert_equal(frogs.find_method_by_id(:fetch_frog).name, 'POST')
    assert_equal(frogs.find_method_by_http_method('POST').id, 'fetch_frog')
  end

  # Dereference a resource's method.
  def test_find_dereferenced_method
    green_things = @wadl.find_resource(:green_things)
    assert_equal(green_things.find_method_by_id(:fetch).name, 'GET')
  end

end

class PathParameters < WADLTest

  def setup
    @wadl = wadl(<<-EOT)
<resources base="http://www.example.com/">
  <resource id="mad" path="im/mad/because">
    <resource href="#insult" />
  </resource>

  <resource id="insult" path="the/{person}/is/{a}">
    <param name="a" default="dork" style="matrix" />
    <param name="and" style="matrix" />
    <resource id="so-let's" path="so-let's/{do something}" />
  </resource>
</resources>
    EOT
  end

  def test_path_parameter_substitution
    insult_resource = @wadl.find_resource_by_path('the/{person}/is/{a}')

    # Test simple substitution.
    assert_equal(insult_resource.uri(:path => { 'person' => 'king', 'a' => 'fink' }),
                 'http://www.example.com/the/king/is/;a=fink')
    # Test default values.
    assert_equal(insult_resource.uri(:path => { 'person' => 'king' }),
                 'http://www.example.com/the/king/is/;a=dork')

    # Test use of optional paramaters.
    assert_equal(insult_resource.uri(:path => { 'person' => 'king', 'a' => 'fink',
                                                'and' => 'he can bite me' }),
                 'http://www.example.com/the/king/is/;a=fink/;and=he%20can%20bite%20me')

    # Don't provide required argument.
    assert_raises(ArgumentError) { insult_resource.uri }

    # Provide multiple values for single-valued argument.
    assert_raises(ArgumentError) {
      insult_resource.uri(:path => { :person => 'king', :a => ['fink', 'dolt'] })
    }
  end

  # Test enumerated options for parameters
  def test_options
    resource = wadl(<<-EOT).find_resource('fate')
<resources base="http://www.example.com/">
  <resource id="fate" path="fates/{fate}">
    <param name="fate">
      <option value="Clotho" />
      <option value="Lachesis" />
      <option value="Atropos" />
    </param>
  </resource>
</resources>
    EOT

    assert_equal(resource.uri(:path => { :fate => 'Clotho' }),
                 'http://www.example.com/fates/Clotho')

    assert_raises(ArgumentError) { resource.uri(:path => { :fate => 'Groucho' }) }
  end

  # This one's complicated. We bind a resource's path parameters to
  # specific values, then get a sub-resource of the bound resource and
  # bind _its_ path parameters. This tests the BoundResource delegate
  # class.
  def test_bound_resource_traversal
    im_mad_because = @wadl.find_resource('mad')
    assert_equal(im_mad_because.uri, 'http://www.example.com/im/mad/because')

    insult = im_mad_because.find_resource('insult')
    assert_equal(insult.uri(:path => { 'person' => 'king', 'a' => 'fink' }),
                  'http://www.example.com/im/mad/because/the/king/is/;a=fink')

    im_mad_because_hes_a_fink = insult.bind!(:path => { 'person' => 'king', 'a' => 'fink' })
    assert_equal(im_mad_because_hes_a_fink.uri,
                 'http://www.example.com/im/mad/because/the/king/is/;a=fink')

    im_mad_because_hes_a_fink_lets = im_mad_because_hes_a_fink.find_resource("so-let's")
    assert_equal(im_mad_because_hes_a_fink_lets.uri(:path => { 'do something' => 'revolt' }),
                 "http://www.example.com/im/mad/because/the/king/is/;a=fink/so-let's/revolt")

    im_mad_because_hes_a_fink_lets_revolt = im_mad_because_hes_a_fink_lets.
      bind(:path => { 'person' => 'fink', 'do something' => 'revolt' })

    assert_equal(im_mad_because_hes_a_fink_lets_revolt.uri,
                 "http://www.example.com/im/mad/because/the/king/is/;a=fink/so-let's/revolt")
  end

  def test_repeating_arguments
    text = <<-EOT
<resources base="http://www.example.com/">
  <resource id="list" path="i/want/{a}">
    <param name="a" repeating="true" style="%s" />
  </resource>
</resources>
    EOT

    # NOTE: Repeating plain arguments get separated by commas
    # (an arbitrary decision on my part).
    { 'plain'  => 'http://www.example.com/i/want/pony,water%20slide,BB%20gun',
      'matrix' => 'http://www.example.com/i/want/;a=pony;a=water%20slide;a=BB%20gun' }.each { |style, uri|
      list = wadl(text % style).find_resource('list')
      assert_equal(list.uri(:path => { :a => ['pony', 'water slide', 'BB gun'] }), uri)
    }
  end

  def test_fixed_values
    poll = wadl(<<-EOT).find_resource('poll')
<resources base="http://www.example.com/">
  <resource id="poll" path="big-brother-is/{opinion}">
    <param name="opinion" fixed="doubleplusgood" />
  </resource>
</resources>
    EOT

    assert_equal(poll.uri(:opinion => 'ungood'),
                 'http://www.example.com/big-brother-is/doubleplusgood')
  end

  def test_matrix_values
    lights = wadl(<<-EOT).find_resource('blinkenlights')
<resources base="http://www.example.com/">
  <resource id="blinkenlights" path="light-panel/{light1}{light2}{light3}">
    <param name="light1" type="xsd:boolean" style="matrix" fixed="true" />
    <param name="light2" type="xsd:boolean" style="matrix" fixed="false" />
    <param name="light3" type="xsd:boolean" style="matrix" />
  </resource>
</resources>
    EOT

    on_uri  = 'http://www.example.com/light-panel/;light1;light3'
    off_uri = 'http://www.example.com/light-panel/;light1'

    assert_equal(lights.uri(:path => { :light3 => 'true' }), on_uri)
    assert_equal(lights.uri(:path => { :light3 => '1'    }), on_uri)

    assert_equal(lights.uri, off_uri)
    assert_equal(lights.uri(:path => { :light3 => 'false' }), off_uri)
    assert_equal(lights.uri(:path => { :light3 => false   }), off_uri)
    assert_equal(lights.uri(:path => { :light3 => 'True'  }), off_uri)
    assert_equal(lights.uri(:path => { :light3 => true    }), off_uri)
  end

  def test_template_params_with_basic_auth
    service = wadl(<<-EOT).resource(:service_id_json)
<resources base="http://www.example.com/">
  <resource path="service/{id}.json" id="service_id_json">
    <param name="Authorization" style="header"/>
    <param name="id" style="template" type="plain"/>
    <method name="DELETE" id="DELETE-service_id_json">
      <request></request>
      <response></response>
    </method>
    <method name="PUT" id="PUT-service_id_json">
      <request>
        <param name="body" style="header" type="application/json"/>
      </request>
      <response></response>
    </method>
    <method name="GET" id="GET-service_id_json">
      <request></request>
      <response>
        <representation type="application/json"/>
      </response>
    </method>
  </resource>
</resources>
    EOT

    arg = { :path => { :id => 42 } }
    uri = 'http://www.example.com/service/42.json'

    assert_equal(uri, u1 = service.bind(arg).uri)
    assert_equal(nil, u1.headers['Authorization'])

    assert_equal(uri, u2 = service.with_basic_auth('u', 'p').bind(arg).uri)
    assert_equal("Basic dTpw\n", u2.headers['Authorization'])
  end

end

class RequestFormatTests < WADLTest

  def setup
    @wadl = wadl(<<-EOT)
<resources base="http://www.example.com/">
  <resource id="top" path="palette">
    <param style="form" name="api_key" />
    <resource id="color" path="colors/{color}">
      <method href="#get_graphic" />
      <method href="#set_graphic" />
    </resource>
  </resource>
</resources>

<method name="GET" id="get_graphic">
  <request>
    <param name="shade" type="xsd:string" required="true" />
  </request>
</method>

<method name="POST" id="set_graphic">
  <request>
    <representation mediaType="application/x-www-form-urlencoded">
      <param name="new_graphic" type="xsd:string" required="true" />
      <param name="filename" type="xsd:string" required="true" />
    </representation>
  </request>
</method>
    EOT

    @color = @wadl.find_resource('top').bind(:query => { :api_key => 'foobar' }).find_resource('color')
  end

  def test_query_vars
    graphic = @color.find_method('get_graphic')
    path    = { :color => 'blue' }
    query   = { :shade => 'light' }

    assert_equal(graphic.request.uri(@color, :path => path, :query => query),
                 'http://www.example.com/palette/colors/blue?shade=light')

    assert_raises(ArgumentError) { graphic.request.uri(@color, path) }
  end

  def test_representation
    graphic = @color.find_method('set_graphic')
    representation = graphic.request.find_form

    assert_equal(representation % { :new_graphic => 'foobar', 'filename' => 'blue.jpg' },
                 'new_graphic=foobar&filename=blue.jpg')

    assert_raises(ArgumentError) { representation % { :new_graphic => 'foobar' } }
  end

end
