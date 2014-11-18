require 'miasma'

module Miasma
  module Types

    # Remote API connection
    class Api

      include Miasma::Utils::Lazy
      include Miasma::Utils::Memoization

      # Create new API connection
      #
      # @param creds [Smash] credentials
      # @return [self]
      def initialize(creds)
        if(creds.is_a?(Hash))
          load_data(creds)
        else
          raise TypeError.new "Expecting `credentials` to be of type `Hash`. Received: `#{creds.class}`"
        end
        connect
      end

      # @return [Symbol] name of provider
      def provider
        Utils.snake(self.class.to_s.split('::').last).to_sym
      end

      # Connect to the remote API
      #
      # @return [self]
      def connect
        self
      end

      # Build new API for specified type using current provider / creds
      #
      # @param type [Symbol] api type
      # @return [Api]
      def api_for(type)
        memoize(type) do
          Miasma.api(
            Smash.new(
              :type => type,
              :provider => provider,
              :credentials => attributes
            )
          )
        end
      end

      # @return [HTTP]
      def connection
        HTTP.with_headers('User-Agent' => "miasma/v#{Miasma::VERSION}")
      end

      # @return [String] url endpoint
      def endpoint
        'http://api.example.com'
      end

      # Perform request to remote API
      #
      # @param args [Hash] options
      # @option args [String, Symbol] :method HTTP request method
      # @option args [String] :path request path
      # @option args [Integer] :expects expected response status code
      # @return [Smash] {:result => HTTP::Response, :headers => Smash, :body => Object}
      # @raises [Error::ApiError::RequestError]
      def request(args)
        args = args.to_smash
        http_method = args.fetch(:method, 'get').to_s.downcase.to_sym
        unless(HTTP::Request::METHODS.include?(http_method))
          raise ArgumentError.new 'Invalid request method provided!'
        end
        request_args = [].tap do |ary|
          _endpoint = args.delete(:endpoint) || endpoint
          ary.push(
            File.join(_endpoint, args[:path].to_s)
          )
          options = {}.tap do |opts|
            [:form, :params, :json, :body].each do |key|
              opts[key] = args[key] if args[key]
            end
          end
          ary.push(options) unless options.empty?
        end
        if(args[:headers])
          _connection = connection.with_headers(args[:headers])
          args.delete(:headers)
        else
          _connection = connection
        end
        result = make_request(_connection, http_method, request_args)
        unless(result.code == args.fetch(:expects, 200).to_i)
          raise Error::ApiError::RequestError.new(result.reason, :response => result)
        end
        format_response(result)
      end

      # Perform request
      #
      # @param connection [HTTP]
      # @param http_method [Symbol]
      # @param request_args [Array]
      # @return [HTTP::Response]
      # @note this is mainly here for concrete APIs to
      #   override if things need to be done prior to
      #   the actual request (like signature generation)
      def make_request(connection, http_method, request_args)
        connection.send(http_method, *request_args)
      end

      # Makes best attempt at formatting response
      #
      # @param result [HTTP::Response]
      # @return [Smash]
      def format_response(result)
        extracted_headers = Smash[result.headers.map{|k,v| [Utils.snake(k), v]}]
        if(extracted_headers[:content_type].end_with?('json'))
          begin
            extracted_body = MultiJson.load(result.body.to_s).to_smash
          rescue MultiJson::ParseError
            extracted_body = result.body.to_s
          end
        elsif(extracted_headers[:content_type].end_with?('xml'))
          begin
            extracted_body = MultiXml.parse(result.body.to_s).to_smash
          rescue MultiXml::ParseError
            extracted_body = result.body.to_s
          end
        else
          extracted_body = result.body.to_s
        end
        Smash.new(
          :response => result,
          :headers => extracted_headers,
          :body => extracted_body
        )
      end

    end

  end
end
