require "uri"
require "httpi/response"

module HTTPI
  module Adapter

    # = HTTPI::Adapter::NetHTTPPersistent
    #
    # Adapter for the Net::NetHTTPPersistent client.
    # http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/
    class NetHTTPPersistent

      def initialize(request)
        self.client = new_client request
      end

      attr_reader :client

      # Executes an HTTP GET request.
      # @see HTTPI.get
      def get(request)
        do_request :get, request do |http, get|
          http.request request.url, get
        end
      end

      # Executes an HTTP POST request.
      # @see HTTPI.post
      def post(request)
        do_request :post, request do |http, post|
          post.body = request.body
          http.request request.url, post
        end
      end

      # Executes an HTTP HEAD request.
      # @see HTTPI.head
      def head(request)
        do_request :head, request do |http, head|
          http.request request.url, head
        end
      end

      # Executes an HTTP PUT request.
      # @see HTTPI.put
      def put(request)
        do_request :put, request do |http, put|
          put.body = request.body
          http.request request.url, put
        end
      end

      # Executes an HTTP DELETE request.
      # @see HTTPI.delete
      def delete(request)
        do_request :delete, request do |http, delete|
          http.request request.url, delete
        end
      end

    private

      attr_writer :client

      def new_client(request)
        proxy_url = request.proxy || URI("")
        # proxy = Net::HTTP::Proxy(proxy_url.host, proxy_url.port, proxy_url.user, proxy_url.password)
        # proxy.new request.url.host, request.url.port
        # FIXME later
        Net::HTTP::Persistent.new("httpi_adapter_for_#{request}#{Thread.current.object_id}")
      end

      def do_request(type, request)
        setup_client request
        setup_ssl_auth request.auth.ssl if request.auth.ssl?

        # respond_with(client.start do |http|
        #   yield http, request_client(type, request)
        # end)
        # respond_with(client.request(request.url, request_client(type, request)))
        respond_with(yield(client, request_client(type, request)))
      end

      def setup_client(request)
        client.open_timeout = request.open_timeout if request.open_timeout
        client.read_timeout = request.read_timeout if request.read_timeout
      end

      def setup_ssl_auth(ssl)
        client.private_key = ssl.cert_key
        client.certificate = ssl.cert
        client.ca_file = ssl.ca_cert_file if ssl.ca_cert_file unless ssl.verify_mode == :none
        client.verify_mode = ssl.openssl_verify_mode
      end

      def request_client(type, request)
        request_class = case type
          when :get    then Net::HTTP::Get
          when :post   then Net::HTTP::Post
          when :head   then Net::HTTP::Head
          when :put    then Net::HTTP::Put
          when :delete then Net::HTTP::Delete
        end

        request_client = request_class.new request.url.request_uri, request.headers
        request_client.basic_auth *request.auth.credentials if request.auth.basic?

        request_client
      end

      def respond_with(response)
        headers = response.to_hash
        headers.each { |key, value| headers[key] = value[0] }
        Response.new response.code, headers, response.body
      end

    end
  end
end
