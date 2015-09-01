require 'miasma'

module Miasma
  module Types

    # Remote API connection
    class Api

      # HTTP request methods that are allowed retry
      VALID_REQUEST_RETRY_METHODS=[:get, :head]
      # Maximum allowed HTTP request retries (for non-HTTP related errors)
      MAX_REQUEST_RETRIES=5

      include Miasma::Utils::Lazy
      include Miasma::Utils::Memoization

      # Create new API connection
      #
      # @param creds [Smash] credentials
      # @return [self]
      def initialize(creds)
        custom_setup(creds)
        if(creds.is_a?(Hash))
          load_data(creds)
        else
          raise TypeError.new "Expecting `credentials` to be of type `Hash`. Received: `#{creds.class}`"
        end
        connect
      end

      # Simple hook for concrete APIs to make adjustments prior to
      # initialization and connection
      #
      # @param creds [Hash]
      # @return [TrueClass]
      def custom_setup(creds)
        true
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
      # @option args [Integer, Array<Integer>] :expects expected response status code
      # @option args [TrueClass, FalseClass] :disable_body_extraction do not auto-parse response body
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
        result = retryable_request(http_method) do
          res = make_request(_connection, http_method, request_args)
          unless([args.fetch(:expects, 200)].flatten.compact.map(&:to_i).include?(res.code))
            raise Error::ApiError::RequestError.new(res.reason, :response => res)
          end
          res
        end
        format_response(result, !args[:disable_body_extraction])
      end

      # If HTTP request method is allowed to be retried then retry
      # request on non-response failures. Otherwise just re-raise
      # immediately
      #
      # @param http_method [Symbol] HTTP request method
      # @yield request to be retried if allowed
      # @return [Object] result of block
      def retryable_request(http_method, &block)
        Bogo::Retry.build(
          data.fetch(:retry_type, :exponential),
          :max_attempts => VALID_REQUEST_RETRY_METHODS.include?(http_method) ? data.fetch(:retry_max, MAX_REQUEST_RETRIES) : 1,
          :wait_interval => data[:retry_interval],
          :ui => data[:retry_ui],
          :auto_run => false,
          &block
        ).run!
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
      # @param extract_body [TrueClass, FalseClass] automatically extract body
      # @return [Smash]
      def format_response(result, extract_body=true)
        extracted_headers = Smash[result.headers.map{|k,v| [Utils.snake(k), v]}]
        if(extract_body)
          body_content = result.body.to_s
          body_content.encode!('UTF-8', 'binary',
            :invalid => :replace,
            :undef => :replace,
            :replace => ''
          )
          if(extracted_headers[:content_type].to_s.include?('json'))
            extracted_body = from_json(body_content) || body_content
          elsif(extracted_headers[:content_type].to_s.include?('xml'))
            extracted_body = from_xml(body_content) || body_content
          else
            extracted_body = from_json(body_content) ||
              from_xml(body_content) ||
              body_content
          end
        end
        unless(extracted_body)
          # @note if body is over 100KB, do not extract
          if(extracted_headers[:content_length].to_i < 102400)
            extracted_body = result.body.to_s
          else
            extracted_body = result.body
          end
        end
        Smash.new(
          :response => result,
          :headers => extracted_headers,
          :body => extracted_body
        )
      end

      # Convert from JSON
      #
      # @param string [String]
      # @return [Hash, Array, NilClass]
      def from_json(string)
        begin
          MultiJson.load(string).to_smash
        rescue MultiJson::ParseError
          nil
        end
      end

      # Convert from JSON
      #
      # @param string [String]
      # @return [Hash, Array, NilClass]
      def from_xml(string)
        begin
          MultiXml.parse(string).to_smash
        rescue MultiXml::ParseError
          nil
        end
      end

    end

  end
end
