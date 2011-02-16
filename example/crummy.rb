require 'wadl'

crummy = WADL::Application.from_wadl(open("crummy.wadl"))
add_resource = crummy.find_resource(:add)

repr_format = add_resource.find_method(:add).request.representations[0]
representation = repr_format % {:password => 'mypassword', 
                                :entry => 'This is an entry',
                                :title => 'The title!' }
result = add_resource.post(:path => {:weblog => "personal"},
                           :send_representation => representation)
if format = result.format and format.id == 'CreatedAtURI'
  puts "Success!"
  puts result.headers['Location']
else
  puts result
end
