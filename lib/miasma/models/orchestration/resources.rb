require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Stack

        # Abstract stack resources collection
        class Resources < Types::Collection

          # @return [Miasma::Models::Orchestration::Stack]
          attr_reader :stack

          # Override to capture originating stack
          #
          # @param stack [Stack]
          def initialize(stack)
            @stack = stack
            super stack.api
          end

          # Return resources matching given filter
          #
          # @param options [Hash] filter options
          # @return [Array<Resources>]
          def filter(options={})
            raise NotImplementedError
          end

          # Build a new resource instance
          #
          # @param args [Hash] creation options
          # @return [Resource]
          def build(args={})
            Resource.new(stack, args.to_smash)
          end

          protected

          # @return [Array<Resources>]
          def perform_population
            api.resource_all(stack)
          end

        end

      end
    end
  end
end
