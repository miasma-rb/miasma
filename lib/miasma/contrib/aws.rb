require 'miasma'
require 'miasma/utils/smash'
require 'time'

module Miasma
  module Contrib

    class AwsApiCore

      class Hmac

        attr_reader :digest
        attr_reader :key

        def initialize(kind, key)
          @digest = OpenSSL::Digest.new(kind)
          @key = key
        end

        def to_s
          "Hmac#{digest.name}"
        end

        def sign(data)
          OpenSSL::HMAC.digest(digest, key, data)
        end

      end

      def initialize(credentials)
        @credentials = credentials
      end

      def identify_and_load

      end

    end

  end
end
