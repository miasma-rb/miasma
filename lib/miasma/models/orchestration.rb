require 'miasma'

module Miasma
  module Models
    # Abstract orchestration API
    class Orchestration < Types::Api

      autoload :Stack, 'miasma/models/orchestration/stack'
      autoload :Stacks, 'miasma/models/orchestration/stacks'

      # @return [Smash] mapping of remote type to internal type
      RESOURCE_MAPPING = Smash.new

      ## mapping example
      # RESOURCE_MAPPING = Smash.new(
      #   'AWS::EC2::Instance' => Smash.new(
      #     :api => :compute,
      #     :collection => :servers
      #   )
      # )

      # @return [Array<Symbol>] valid resource states
      VALID_RESOURCE_STATES = [
        :create_complete, :create_in_progress, :create_failed,
        :delete_complete, :delete_in_progress, :delete_failed,
        :rollback_complete, :rollback_in_progress, :rollback_failed,
        :update_complete, :update_in_progress, :update_failed,
        :update_rollback_complete, :update_rollback_in_progress,
        :update_rollback_failed, :unknown
      ]

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

      # Fetch stack template
      #
      # @param stack [Stack]
      # @return [Smash] stack template
      def stack_template_load(stack)
        raise NotImplementedError
      end

      # Validate stack template
      #
      # @param stack [Stack]
      # @return [NilClass, String] nil if valid, string error message if invalid
      def stack_template_validate(stack)
        raise NotImplementedError
      end

      # Plan stack update
      #
      # @param stack [Stack]
      # @return [Hash]
      def stack_plan(stack)
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
