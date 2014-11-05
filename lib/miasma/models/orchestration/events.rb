require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Stack

        # Abstract stack resources collection
        class Events < Types::Collection

          # @return [Miasma::Models::Orchestration::Stack]
          attr_reader :stack

          # Override to capture originating stack
          #
          # @param stack [Stack]
          def initialize(stack)
            @stack = stack
            super stack.api
          end

          # Return events matching given filter
          #
          # @param options [Hash] filter options
          # @return [Array<Event>]
          def filter(options={})
            raise NotImplementedError
          end

          # Build a new event instance
          #
          # @param args [Hash] creation options
          # @return [Event]
          def build(args={})
            Event.new(stack, args.to_smash)
          end

          # @return [Event] collection item class
          def model
            Event
          end

          # Fetch any new events and add to collection
          #
          # @return [Array<Event>] new events fetched
          def update!
            new_events = api.event_all_new(self)
            self.all += new_events
            new_events
          end

          protected

          # @return [Array<Event>]
          def perform_population
            api.event_all(stack)
          end

        end

      end
    end
  end
end
