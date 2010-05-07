require 'wadl'

yahoo = WADL::Application.from_wadl(open("yahoo.wadl"))
search_resource = yahoo.find_resource(:newsSearch)
expected_representation = search_resource.find_method(:search).response.representations[0]
result = search_resource.get({:appid => "selectric", :query => "bar"},
                             expected_representation)
puts result.representation

begin
  search_resource.get(:query => "bar")
rescue ArgumentError
  puts "Couldn't call method without providing value for required variable. (Good)"
end
