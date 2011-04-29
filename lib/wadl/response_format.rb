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

begin
  require 'mime/types'
rescue LoadError
end

require 'wadl'

module WADL

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
          t = f.dereference.mediaType and response_media_type.index(t) == 0
        }

        # If an exact media type match fails, use the mime-types gem to
        # match the response to a response format using the underlying
        # subtype. This will match "application/xml" with "text/xml".
        response_format ||= begin
          mime_type = MIME::Types[response_media_type]
          raw_sub_type = mime_type[0].raw_sub_type if mime_type && !mime_type.empty?

          representations.find { |f|
            if t = f.dereference.mediaType
              response_mime_type = MIME::Types[t]
              response_raw_sub_type = response_mime_type[0].raw_sub_type if response_mime_type && !response_mime_type.empty?
              response_raw_sub_type == raw_sub_type
            end
          }
        end if defined?(MIME::Types)

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

end
