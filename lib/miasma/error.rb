require 'miasma'

module Miasma
  # Generic Error class
  class Error < StandardError

    # Create new error instance
    #
    # @param msg [String] error message
    # @param args [Hash] optional arguments
    # @return [self]
    def initialize(msg, args={})
      super msg
    end

    # Api related errors
    class ApiError < Error

      # @return [HTTP::Response] result of bad request
      attr_reader :response

      # Create new API error instance
      #
      # @param msg [String] error message
      # @param args [Hash] optional arguments
      # @option args [HTTP::Response] :response response from request
      def initialize(msg, args={})
        super
        @response = args.to_smash[:response]
      end

      # Api request error
      class RequestError < ApiError; end

      # Api authentication error
      class AuthenticationError < ApiError; end

    end

    # Orchestration error
    class OrchestrationError < Error
      # Template failed to validate
      class InvalidTemplate < OrchestrationError
      end
    end

  end
end
