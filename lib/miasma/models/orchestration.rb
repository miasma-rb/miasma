require 'miasma'

module Miasma
  module Models
    # Abstract orchestration API
    class Orchestration < Types::Api

      autoload :Server, 'miasma/models/orchestration/stack'
      autoload :Servers, 'miasma/models/orchestration/stacks'

      # Orchestration stacks
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::Orchestration::Stack>] stacks
      def stacks(args={})
        memoize(:stacks) do
          Stacks.new(self)
        end
      end

      # Save the stack
      #
      # @param stack [Models::Orchestration::Stack]
      # @return [Models::Orchestration::Stack]
      def stack_save(stack)
        raise NotImplementedError
      end

      # Reload the stack data from the API
      #
      # @param stack [Models::Orchestration::Stack]
      # @return [Models::Orchestration::Stack]
      def stack_reload(stack)
        raise NotImplementedError
      end

      # Delete the stack
      #
      # @param stack [Models::Orchestration::Stack]
      # @return [TrueClass, FalseClass]
      def stack_destroy(stack)
        raise NotImplementedError
      end

      # Return all stacks
      #
      # @param options [Hash] filter
      # @return [Array<Models::Orchestration::Stack>]
      def stack_all(options={})
        raise NotImplementedError
      end

    end
  end
end
