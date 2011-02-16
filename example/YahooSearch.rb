require 'wadl'

yahoo = WADL::Application.from_wadl(open("YahooSearch.wadl"))
expected_representation = yahoo.newsSearch.search.response.representations[0]
result = yahoo.newsSearch.get(:query => {:appid => "selectric", :query => "bar"},
                              :expected_representation => expected_representation)
puts result.representation
