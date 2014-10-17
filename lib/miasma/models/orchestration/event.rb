require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Stack

        # Stack event
        class Event < Types::Model

          attribute :time, Time, :required => true
          attribute :resource_id, [String, Numeric], :required => true
          attribute :resource_logical_id, [String, Numeric]
          attribute :resource_name, String
          attribute :resource_state, Symbol, :allowed_values => Orchestration::VALID_RESOURCE_STATES
          attribute :resource_status, String
          attribute :resource_status_reason, String

          attr_reader :stack

          def initialize(stack, args={})
            @stack = stack
            super stack.api, args
          end

          # @return [Resource]
          def resource
            stack.resources.get(self.resource_id)
          end

          include Utils::Immutable

        end

      end
    end
  end
end
