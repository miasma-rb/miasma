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

      # Connect to the remote API
      #
      # @return [self]
      def connect
        self
      end

      # @return [HTTP]
      def connection
        HTTP
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
        unless(HTTP.public_methods.include?(http_method))
          raise ArgumentError.new 'Invalid request method provided!'
        end
        request_args = [].tap do |ary|
          ary.push(
            File.join(endpoint, args[:path].to_s)
          )
          options = {}.tap do |opts|
            [:form, :params, :json, :body].each do |key|
              opts[key] = args[key] if args[key]
            end
          end
          ary.push(options) unless options.empty?
        end
        result = connection.send(http_method, *request_args)
        unless(result.code == args.fetch(:expects, 200).to_i)
          raise Error::ApiError::RequestError.new(result.reason, :response => result)
        end
        extracted_headers = Smash[result.headers.map{|k,v| [Utils.snake(k), v]}]
        if(extracted_headers[:content_type] == 'application/json')
          begin
            extracted_body = MultiJson.load(result.body.to_s).to_smash
          rescue MultiJson::ParseError
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
