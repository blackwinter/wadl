#--
###############################################################################
#                                                                             #
# wadl -- Super cheap Ruby WADL client                                        #
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

require 'wadl/version'

module WADL

  autoload :Address,                 'wadl/address'
  autoload :Application,             'wadl/application'
  autoload :CheapSchema,             'wadl/cheap_schema'
  autoload :Documentation,           'wadl/documentation'
  autoload :FaultFormat,             'wadl/fault_format'
  autoload :Fault,                   'wadl/fault'
  autoload :HasDocs,                 'wadl/has_docs'
  autoload :HTTPMethod,              'wadl/http_method'
  autoload :Link,                    'wadl/link'
  autoload :Option,                  'wadl/option'
  autoload :Param,                   'wadl/param'
  autoload :RepresentationContainer, 'wadl/representation_container'
  autoload :RepresentationFormat,    'wadl/representation_format'
  autoload :RequestFormat,           'wadl/request_format'
  autoload :ResourceAndAddress,      'wadl/resource_and_address'
  autoload :ResourceContainer,       'wadl/resource_container'
  autoload :Resource,                'wadl/resource'
  autoload :Resources,               'wadl/resources'
  autoload :ResourceType,            'wadl/resource_type'
  autoload :ResponseFormat,          'wadl/response_format'
  autoload :Response,                'wadl/response'
  autoload :URIParts,                'wadl/uri_parts'
  autoload :XMLRepresentation,       'wadl/xml_representation'

end
