require 'miasma'

module Miasma
  module Models
    class Orchestration

      # Abstract stack collection
      class Stacks < Types::Collection

        # Locate stack by name or ID
        #
        # @param ident [String, Numeric] name or ID
        # @return [Stack]
        def get(ident)
          all.detect do |stack|
            stack.id.to_s == ident.to_s ||
              stack.name.to_s == ident.to_s
          end
        end

        # Return stacks matching given filter
        #
        # @param options [Hash] filter options
        # @option options [String] :state current stack state
        # @return [Array<Stack>]
        def filter(options={})
          raise NotImplementedError
        end

        # Build a new stack instance
        #
        # @param args [Hash] creation options
        # @return [Stack]
        def build(args={})
          Stack.new(api, args.to_smash)
        end

        # @return [Stack] collection items class
        def model
          Stack
        end

        protected

        # @return [Array<Stack>]
        def perform_population
          api.stack_all
        end

      end

    end
  end
end
