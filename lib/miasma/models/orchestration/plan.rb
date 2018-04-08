require "miasma"

module Miasma
  module Models
    class Orchestration
      class Stack
        # Stack update plan
        class Plan < Types::Model
          attr_reader :stack

          def initialize(stack, args = {})
            @stack = stack
            super stack.api, args
          end

          class Diff < Types::Data
            attribute :name, String, :required => true
            attribute :current, String, :required => true
            attribute :proposed, String, :required => true
          end

          # Plan item
          class Item < Types::Data
            attribute :name, String, :required => true
            attribute :type, String, :required => true
            attribute :diffs, Diff, :multiple => true
          end

          attribute :add, Item, :multiple => true
          attribute :remove, Item, :multiple => true
          attribute :replace, Item, :multiple => true
          attribute :interrupt, Item, :multiple => true
          attribute :unavailable, Item, :multiple => true
          attribute :unknown, Item, :multiple => true

          # Apply this stack plan
          #
          # @return [Stack]
          def apply!
            if self == stack.plan
              stack.plan_apply
            else
              raise Error::OrchestrationError::InvalidStackPlan.new "Plan is no longer valid for linked stack."
            end
            stack.reload
          end

          # Destroy this stack plan
          #
          # @return [Stack]
          def destroy
            if self == stack.plan
              stack.plan_destroy
            else
              raise Error::OrchestrationError::InvalidStackPlan.new "Plan is no longer valid for linked stack."
            end
            stack.reload
          end

          # Proxy reload action up to the API
          def perform_reload
            api.plan_reload(self)
          end

          include Utils::Immutable
        end
      end
    end
  end
end
