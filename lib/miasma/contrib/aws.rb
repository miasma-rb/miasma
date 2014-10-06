require 'miasma'
require 'miasma/utils/smash'

require 'time'
require 'openssl'

module Miasma
  module Contrib

    class AwsApiCore

      # HMAC helper class
      class Hmac

        # @return [OpenSSL::Digest]
        attr_reader :digest
        # @return [String] secret key
        attr_reader :key

        # Create new HMAC helper
        #
        # @param kind [String] digest type (sha1, sha512)
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

        # Sign the given data
        #
        # @param data [String]
        # @return [String] signature
        def sign(data)
          OpenSSL::HMAC.digest(digest, key, data)
        end

      end

      class Signature

        def initialize
          raise NotImplementedError.new 'This class should not be used directly!'
        end

        def generate(path, opts={})
          raise NotImplementedError
        end

        def safe_escape(string)
          string.gsub(/([^a-zA-Z0-9_.\-~/) do
            '%' << $1.unpack('H2', $1.bytesize).join('%').upcase
          end
        end

      end

      class SignatureV4 < Signature

        # @return [Hmac]
        attr_reader :hmac
        # @return [String] access key
        attr_reader :access_key
        # @return [String] region
        attr_reader :region

        # Create new signature generator
        #
        # @param access_key [String]
        # @param secret_key [String]
        # @param region [String]
        # @return [self]
        def initialize(access_key, secret_key, region)
          @hmac = Hmac.new('sha256', secret_key)
          @access_key = access_key
          @region = region
        end

        def generate(http_method, path, opts)
          to_sign = [

        end

        def algorithm
          'AWS4-HMAC-SHA256'
        end


        def build_canonical_request(http_method, path, opts)
          [
            http_method.to_s.upcase,
            path,
            canonical_query(opts[:params]),
            canonical_headers(opts[:headers]),
            signed_headers(opts[:headers]),
            canonical_payload(opts)
          ].join("\n")
        end

        def canonical_query(params)
          params ||= {}
          params = Hash[params.sort_by(&:first)]
          query = params.map do |key, value|
            "#{key.downcase}=#{safe_escape(value)}"
          end.join('&')
        end

        def canonical_headers(headers)
          headers ||= {}
          headers = Hash[headers.sort_by(&:first)]
          headers.map do |key, value|
            [key.downcase, value.chomp].join(':')
          end.join("\n")
        end

        def signed_headers(headers)
          headers ||= {}
          headers.sort_by(&:first).map(&:first).
            map(&:downcase).join(';')
        end

        def canonical_payload(options)
          body = options.fetch(:body, '')
          if(options[:json])
            body = MultiJson.dump(options[:json])
          elsif(options[:form])
            body = options[:form] # need urlencode stuff!!!
          else
            ''
          end
          hmac.digest << body
          body = hmac.digest.hexdigest
          hmac.digest.reset
          body
        end

      end

    end

  end

  module Models
    class Compute
      class Aws < Compute

        attribute :aws_access_key_id, String, :required => true
        attribute :aws_secret_access_key, String, :required => true
        attribute :aws_region, String, :required => true
        attribute :aws_host, String

        # @return [Contrib::AwsApiCore::SignatureV4]
        attr_reader :signer

        def connect
          unless(aws_host)
            aws_host = "ec2.#{aws_region}.amazonaws.com"
          end
          @signer = Contrib::AwsApiCore::SignatureV4.new(
            aws_access_key_id, aws_secret_access_key, aws_region
          )
        end

        def connection
          super.with_headers(
            'Host' => aws_host
            'X-Amz-Date' => Time.now.utc.strftime('%Y%m%d%T%H%M%SZ')
          )
        end

        # Override to inject signature
        #
        # @param connection [HTTP]
        # @param http_method [Symbol]
        # @param request_args [Array]
        # @return [HTTP::Response]
        def make_request(connection, http_method, request_args)
          signature = signer.generate(http_method, *request_args)
          connection.with_headers(
            'Authorization' => signature
          ).send(http_method, *request_args)
        end

      end
    end
  end

end
