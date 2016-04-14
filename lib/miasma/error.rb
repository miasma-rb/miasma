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
      # @return [String] response error message
      attr_reader :response_error_msg

      # Create new API error instance
      #
      # @param msg [String] error message
      # @param args [Hash] optional arguments
      # @option args [HTTP::Response] :response response from request
      def initialize(msg, args={})
        super
        @response = args.to_smash[:response]
        @message = msg
        extract_error_message(@response)
      end

      # @return [String] provides response error suffix
      def message
        [@message, @response_error_msg].compact.join(' - ')
      end

      # Attempt to extract error message from response
      #
      # @param response [HTTP::Response]
      # @return [String, NilClass]
      def extract_error_message(response)
        begin
          begin
            content = MultiJson.load(response.body.to_s).to_smash
            @response_error_msg = [[:error, :message]].map do |path|
              if(result = content.get(*path))
                "#{content[:code]}: #{result}"
              end
            end.flatten.compact.first
          rescue MultiJson::ParseError
            begin
              content = MultiXml.parse(response.body.to_s).to_smash
              @response_error_msg = [['ErrorResponse', 'Error'], ['Error']].map do |path|
                if(result = content.get(*path))
                  "#{result['Code']}: #{result['Message']}"
                end
              end.compact.first
            rescue MultiXml::ParseError
              content = Smash.new
            end
          rescue
            # do nothing
          end
        end
        @response_error_msg
      end

      # Api request error
      class RequestError < ApiError; end

      # Api authentication error
      class AuthenticationError < ApiError; end

    end

    # Orchestration error
    class OrchestrationError < Error
      # Template failed to validate
      class InvalidTemplate < OrchestrationError; end
      # Stack is not in correct state for planning
      class InvalidPlanState < OrchestrationError; end
      # Plan is no longer valid for stack
      class InvalidStackPlan < OrchestrationError; end
    end

    # Invalid modification request
    class ImmutableError < Error; end

    # Model has not been persisted
    class ModelPersistError < Error; end

  end
end
