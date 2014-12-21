require 'miasma'
require 'miasma/utils/smash'

require 'time'
require 'openssl'

module Miasma
  module Contrib
    # Core API for AWS access
    class AwsApiCore

      module RequestUtils

        # Fetch all results when tokens are being used
        # for paging results
        #
        # @param next_token [String]
        # @param result_key [Array<String, Symbol>] path to result
        # @yield block to perform request
        # @yieldparam options [Hash] request parameters (token information)
        # @return [Array]
        def all_result_pages(next_token, *result_key, &block)
          list = []
          options = next_token ? Smash.new('NextToken' => next_token) : Smash.new
          result = block.call(options)
          content = result.get(*result_key.dup)
          if(content.is_a?(Array))
            list += content
          else
            list << content
          end
          set = result.get(*result_key.slice(0, 3))
          if(set && set['NextToken'])
            list += all_result_pages(set['NextToken'], *result_key, &block)
          end
          list.compact
        end

      end

      # @return [String] current time ISO8601 format
      def self.time_iso8601
        Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
      end

      # HMAC helper class
      class Hmac

        # @return [OpenSSL::Digest]
        attr_reader :digest
        # @return [String] secret key
        attr_reader :key

        # Create new HMAC helper
        #
        # @param kind [String] digest type (sha1, sha256, sha512, etc)
        # @param key [String] secret key
        # @return [self]
        def initialize(kind, key)
          @digest = OpenSSL::Digest.new(kind)
          @key = key
        end

        # @return [String]
        def to_s
          "Hmac#{digest.name}"
        end

        # Generate the hexdigest of the content
        #
        # @param content [String] content to digest
        # @return [String] hashed result
        def hexdigest_of(content)
          digest << content
          hash = digest.hexdigest
          digest.reset
          hash
        end

        # Sign the given data
        #
        # @param data [String]
        # @param key_override [Object]
        # @return [Object] signature
        def sign(data, key_override=nil)
          result = OpenSSL::HMAC.digest(digest, key_override || key, data)
          digest.reset
          result
        end

        # Sign the given data and return hexdigest
        #
        # @param data [String]
        # @param key_override [Object]
        # @return [String] hex encoded signature
        def hex_sign(data, key_override=nil)
          result = OpenSSL::HMAC.hexdigest(digest, key_override || key, data)
          digest.reset
          result
        end

      end

      # Base signature class
      class Signature

        # Create new instance
        def initialize(*args)
          raise NotImplementedError.new 'This class should not be used directly!'
        end

        # Generate the signature
        #
        # @param http_method [Symbol] HTTP request method
        # @param path [String] request path
        # @param opts [Hash] request options
        # @return [String] signature
        def generate(http_method, path, opts={})
          raise NotImplementedError
        end

        # URL string escape compatible with AWS requirements
        #
        # @param string [String] string to escape
        # @return [String] escaped string
        def safe_escape(string)
          string.to_s.gsub(/([^a-zA-Z0-9_.\-~])/) do
            '%' << $1.unpack('H2' * $1.bytesize).join('%').upcase
          end
        end

      end

      # AWS signature version 4
      class SignatureV4 < Signature

        # @return [Hmac]
        attr_reader :hmac
        # @return [String] access key
        attr_reader :access_key
        # @return [String] region
        attr_reader :region
        # @return [String] service
        attr_reader :service

        # Create new signature generator
        #
        # @param access_key [String]
        # @param secret_key [String]
        # @param region [String]
        # @param service [String]
        # @return [self]
        def initialize(access_key, secret_key, region, service)
          @hmac = Hmac.new('sha256', secret_key)
          @access_key = access_key
          @region = region
          @service = service
        end

        # Generate the signature string for AUTH
        #
        # @param http_method [Symbol] HTTP request method
        # @param path [String] request path
        # @param opts [Hash] request options
        # @return [String] signature
        def generate(http_method, path, opts)
          signature = generate_signature(http_method, path, opts)
          "#{algorithm} Credential=#{access_key}/#{credential_scope}, SignedHeaders=#{signed_headers(opts[:headers])}, Signature=#{signature}"
        end

        # Generate URL with signed params
        #
        # @param http_method [Symbol] HTTP request method
        # @param path [String] request path
        # @param opts [Hash] request options
        # @return [String] signature
        def generate_url(http_method, path, opts)
          opts[:params].merge!(
            Smash.new(
              'X-Amz-SignedHeaders' => signed_headers(opts[:headers]),
              'X-Amz-Algorithm' => algorithm,
              'X-Amz-Credential' => "#{access_key}/#{credential_scope}"
            )
          )
          signature = generate_signature(http_method, path, opts.merge(:body => 'UNSIGNED-PAYLOAD'))
          params = opts[:params].merge('X-Amz-Signature' => signature)
          "https://#{opts[:headers]['Host']}/#{path}?#{canonical_query(params)}"
        end

        # Generate the signature
        #
        # @param http_method [Symbol] HTTP request method
        # @param path [String] request path
        # @param opts [Hash] request options
        # @return [String] signature
        def generate_signature(http_method, path, opts)
          to_sign = [
            algorithm,
            AwsApiCore.time_iso8601,
            credential_scope,
            hashed_canonical_request(
              can_req = build_canonical_request(http_method, path, opts)
            )
          ].join("\n")
          signature = sign_request(to_sign)
        end

        # Sign the request
        #
        # @param request [String] request to sign
        # @return [String] signature
        def sign_request(request)
          key = hmac.sign(
            'aws4_request',
            hmac.sign(
              service,
              hmac.sign(
                region,
                hmac.sign(
                  Time.now.utc.strftime('%Y%m%d'),
                  "AWS4#{hmac.key}"
                )
              )
            )
          )
          hmac.hex_sign(request, key)
        end

        # @return [String] signature algorithm
        def algorithm
          'AWS4-HMAC-SHA256'
        end

        # @return [String] credential scope for request
        def credential_scope
          [
            Time.now.utc.strftime('%Y%m%d'),
            region,
            service,
            'aws4_request'
          ].join('/')
        end

        # Generate the hash of the canonical request
        #
        # @param request [String] canonical request string
        # @return [String] hashed canonical request
        def hashed_canonical_request(request)
          hmac.hexdigest_of(request)
        end

        # Build the canonical request string used for signing
        #
        # @param http_method [Symbol] HTTP request method
        # @param path [String] request path
        # @param opts [Hash] request options
        # @return [String] canonical request string
        def build_canonical_request(http_method, path, opts)
          unless(path.start_with?('/'))
            path = "/#{path}"
          end
          [
            http_method.to_s.upcase,
            path,
            canonical_query(opts[:params]),
            canonical_headers(opts[:headers]),
            signed_headers(opts[:headers]),
            canonical_payload(opts)
          ].join("\n")
        end

        # Build the canonical query string used for signing
        #
        # @param params [Hash] query params
        # @return [String] canonical query string
        def canonical_query(params)
          params ||= {}
          params = Hash[params.sort_by(&:first)]
          query = params.map do |key, value|
            "#{safe_escape(key)}=#{safe_escape(value)}"
          end.join('&')
        end

        # Build the canonical header string used for signing
        #
        # @param headers [Hash] request headers
        # @return [String] canonical headers string
        def canonical_headers(headers)
          headers ||= {}
          headers = Hash[headers.sort_by(&:first)]
          headers.map do |key, value|
            [key.downcase, value.chomp].join(':')
          end.join("\n") << "\n"
        end

        # List of headers included in signature
        #
        # @param headers [Hash] request headers
        # @return [String] header list
        def signed_headers(headers)
          headers ||= {}
          headers.sort_by(&:first).map(&:first).
            map(&:downcase).join(';')
        end

        # Build the canonical payload string used for signing
        #
        # @param options [Hash] request options
        # @return [String] body checksum
        def canonical_payload(options)
          body = options.fetch(:body, '')
          if(options[:json])
            body = MultiJson.dump(options[:json])
          elsif(options[:form])
            body = URI.encode_www_form(options[:form])
          end
          if(body == 'UNSIGNED-PAYLOAD')
            body
          else
            hmac.hexdigest_of(body)
          end
        end

      end

      module ApiCommon

        def self.included(klass)
          klass.class_eval do
            attribute :aws_access_key_id, String, :required => true
            attribute :aws_secret_access_key, String, :required => true
            attribute :aws_region, String, :required => true
            attribute :aws_host, String
            attribute :aws_bucket_region, String

            # @return [Contrib::AwsApiCore::SignatureV4]
            attr_reader :signer
          end
        end

        # Build new API for specified type using current provider / creds
        #
        # @param type [Symbol] api type
        # @return [Api]
        def api_for(type)
          memoize(type) do
            creds = attributes.dup
            creds.delete(:aws_host)
            Miasma.api(
              Smash.new(
                :type => type,
                :provider => provider,
                :credentials => creds
              )
            )
          end
        end

        # Setup for API connections
        def connect
          unless(aws_host)
            self.aws_host = [
              self.class::API_SERVICE.downcase,
              aws_region,
              'amazonaws.com'
            ].join('.')
          end
          @signer = Contrib::AwsApiCore::SignatureV4.new(
            aws_access_key_id, aws_secret_access_key, aws_region, self.class::API_SERVICE
          )
        end

        # @return [String] custom escape for aws compat
        def uri_escape(string)
          signer.safe_escape(string)
        end

        # @return [HTTP] connection for requests (forces headers)
        def connection
          super.with_headers(
            'Host' => aws_host,
            'X-Amz-Date' => Contrib::AwsApiCore.time_iso8601
          )
        end

        # @return [String] endpoint for request
        def endpoint
          "https://#{aws_host}"
        end

        # Override to inject signature
        #
        # @param connection [HTTP]
        # @param http_method [Symbol]
        # @param request_args [Array]
        # @return [HTTP::Response]
        # @note if http_method is :post, params will be automatically
        #  removed and placed into :form
        def make_request(connection, http_method, request_args)
          dest, options = request_args
          path = URI.parse(dest).path
          options = options ? options.to_smash : Smash.new
          options[:params] = options.fetch(:params, Smash.new).to_smash.deep_merge('Version' => self.class::API_VERSION)
          if(http_method.to_sym == :post)
            if(options[:form])
              options[:form].merge(options.delete(:params))
            else
              options[:form] = options.delete(:params)
            end
          end
          update_request(connection, options)
          signature = signer.generate(
            http_method, path, options.merge(
              Smash.new(
                :headers => Smash[
                  connection.default_headers.to_a
                ]
              )
            )
          )
          options = Hash[options.map{|k,v|[k.to_sym,v]}]
          connection.auth(signature).send(http_method, dest, options)
        end

        # Simple callback to allow request option adjustments prior to
        # signature calculation
        #
        # @param opts [Smash] request options
        # @return [TrueClass]
        def update_request(con, opts)
          true
        end

      end

    end
  end

  Models::Compute.autoload :Aws, 'miasma/contrib/aws/compute'
  Models::LoadBalancer.autoload :Aws, 'miasma/contrib/aws/load_balancer'
  Models::AutoScale.autoload :Aws, 'miasma/contrib/aws/auto_scale'
  Models::Orchestration.autoload :Aws, 'miasma/contrib/aws/orchestration'
  Models::Storage.autoload :Aws, 'miasma/contrib/aws/storage'
end
