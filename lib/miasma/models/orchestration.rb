require 'miasma'

module Miasma
  module Models
    # Abstract orchestration API
    class Orchestration < Types::Api

      autoload :Server, 'miasma/models/orchestration/stack'
      autoload :Servers, 'miasma/models/orchestration/stacks'
      autoload :Resource, 'miasma/models/orchestration/resource'
      autoload :Resources, 'miasma/models/orchestration/resources'
      autoload :Event, 'miasma/models/orchestration/event'
      autoload :Events, 'miasma/models/orchestration/events'

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

      # Return all resources for stack
      #
      # @param stack [Models::Orchestration::Stack]
      # @return [Array<Models::Orchestration::Stack::Resource>]
      def resource_all(stack)
        raise NotImplementedError
      end

      # Reload the stack resource data from the API
      #
      # @param resource [Models::Orchestration::Stack::Resource]
      # @return [Models::Orchestration::Resource]
      def resource_reload(resource)
        raise NotImplementedError
      end

      # Return all events for stack
      #
      # @param stack [Models::Orchestration::Stack]
      # @return [Array<Models::Orchestration::Stack::Event>]
      def event_all(stack)
        raise NotImplementedError
      end

      # Return all new events for event collection
      #
      # @param events [Models::Orchestration::Stack::Events]
      # @return [Array<Models::Orchestration::Stack::Event>]
      def event_all_new(events)
        raise NotImplementedError
      end

      # Reload the stack event data from the API
      #
      # @param resource [Models::Orchestration::Stack::Event]
      # @return [Models::Orchestration::Event]
      def event_reload(event)
        raise NotImplementedError
      end

    end
  end
end
