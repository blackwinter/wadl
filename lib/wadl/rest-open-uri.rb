require 'open-uri'
require 'net/http'

module OpenURI

  Options.update(
    method: true,
    body:   true
  )

  Methods = Hash.new { |h, k|
    h[k] = begin
      Net::HTTP.const_get(k.to_s.capitalize)
    rescue NameError
    end
  }

  class << self

    alias_method :_wadl_original_check_options, :check_options

    def check_options(options) # :nodoc:
      _wadl_original_check_options(options)

      if m = options[:method] and !Methods[m]
        raise ArgumentError, "unrecognized HTTP method symbol: #{m}"
      end
    end

    def open_http(buf, target, proxy, options) # :nodoc:
      if proxy
        proxy_uri, proxy_user, proxy_pass = proxy
        raise "Non-HTTP proxy URI: #{proxy_uri}" if proxy_uri.class != URI::HTTP
      end

      if target.userinfo && "1.9.0" <= RUBY_VERSION
        # don't raise for 1.8 because compatibility.
        raise ArgumentError, "userinfo not supported.  [RFC3986]"
      end

      header = {}
      options.each {|k, v| header[k] = v if String === k }

      klass = Net::HTTP
      if URI::HTTP === target
        # HTTP or HTTPS
        if proxy
          if proxy_user && proxy_pass
            klass = Net::HTTP::Proxy(proxy_uri.hostname, proxy_uri.port, proxy_user, proxy_pass)
          else
            klass = Net::HTTP::Proxy(proxy_uri.hostname, proxy_uri.port)
          end
        end
        target_host = target.hostname
        target_port = target.port
        request_uri = target.request_uri
      else
        # FTP over HTTP proxy
        target_host = proxy_uri.hostname
        target_port = proxy_uri.port
        request_uri = target.to_s
        if proxy_user && proxy_pass
          header["Proxy-Authorization"] = 'Basic ' + ["#{proxy_user}:#{proxy_pass}"].pack('m').delete("\r\n")
        end
      end

      http = klass.new(target_host, target_port)
      if target.class == URI::HTTPS
        require 'net/https'
        http.use_ssl = true
        http.verify_mode = options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
        store = OpenSSL::X509::Store.new
        if options[:ssl_ca_cert]
          if File.directory? options[:ssl_ca_cert]
            store.add_path options[:ssl_ca_cert]
          else
            store.add_file options[:ssl_ca_cert]
          end
        else
          store.set_default_paths
        end
        http.cert_store = store
      end
      if options.include? :read_timeout
        http.read_timeout = options[:read_timeout]
      end

      resp = nil
      http.start {
        ### rest-open-uri BEGIN
        #req = Net::HTTP::Get.new(request_uri, header)
        req = Methods[options.fetch(:method, :get)].new(request_uri, header)
        req.body = options[:body] if req.request_body_permitted?
        ### rest-open-uri END

        if options.include? :http_basic_authentication
          user, pass = options[:http_basic_authentication]
          req.basic_auth user, pass
        end
        http.request(req) {|response|
          resp = response
          if options[:content_length_proc] && Net::HTTPSuccess === resp
            if resp.key?('Content-Length')
              options[:content_length_proc].call(resp['Content-Length'].to_i)
            else
              options[:content_length_proc].call(nil)
            end
          end
          resp.read_body {|str|
            buf << str
            if options[:progress_proc] && Net::HTTPSuccess === resp
              options[:progress_proc].call(buf.size)
            end
          }
        }
      }
      io = buf.io
      io.rewind
      io.status = [resp.code, resp.message]
      resp.each {|name,value| buf.io.meta_add_field name, value }
      case resp
      when Net::HTTPSuccess
      when Net::HTTPMovedPermanently, # 301
           Net::HTTPFound, # 302
           Net::HTTPSeeOther, # 303
           Net::HTTPTemporaryRedirect # 307
        begin
          loc_uri = URI.parse(resp['location'])
        rescue URI::InvalidURIError
          raise OpenURI::HTTPError.new(io.status.join(' ') + ' (Invalid Location URI)', io)
        end
        throw :open_uri_redirect, loc_uri
      else
        raise OpenURI::HTTPError.new(io.status.join(' '), io)
      end
    end

  end

end
