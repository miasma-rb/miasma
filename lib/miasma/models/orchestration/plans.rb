require "miasma"

module Miasma
  module Models
    class Orchestration
      class Stack
        # Abstract stack plans collection
        class Plans < Types::Collection

          # @return [Miasma::Models::Orchestration::Stack]
          attr_reader :stack

          # Override to capture originating stack
          #
          # @param stack [Stack]
          def initialize(stack)
            @stack = stack
            super stack.api
          end

          # Return plans matching given filter
          #
          # @param options [Hash] filter options
          # @return [Array<Plans>]
          def filter(options = {})
            raise NotImplementedError
          end

          # Build a new plan instance
          #
          # @param args [Hash] creation options
          # @return [Plan]
          def build(args = {})
            Plan.new(stack, args.to_smash)
          end

          # @return [Plan] collection item class
          def model
            Plan
          end

          protected

          # @return [Array<Plan>]
          def perform_population
            api.plan_all(stack)
          end
        end
      end
    end
  end
end
