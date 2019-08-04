require "miasma"

module Miasma
  module Models
    class Orchestration
      # Abstract server
      class Stack < Types::Model

        # Stack states which are valid to execute update plan
        VALID_PLAN_STATES = [
          :create_complete, :update_complete, :update_failed,
          :rollback_complete, :rollback_failed, :unknown,
        ]

        autoload :Resource, "miasma/models/orchestration/resource"
        autoload :Resources, "miasma/models/orchestration/resources"
        autoload :Event, "miasma/models/orchestration/event"
        autoload :Events, "miasma/models/orchestration/events"
        autoload :Plan, "miasma/models/orchestration/plan"
        autoload :Plans, "miasma/models/orchestration/plans"

        include Miasma::Utils::Memoization

        # Stack output
        class Output < Types::Data
          attribute :key, String, :required => true
          attribute :value, String, :required => true
          attribute :description, String

          attr_reader :stack

          def initialize(stack, args = {})
            @stack = stack
            super args
          end
        end

        attribute :name, String, :required => true
        attribute :description, String
        attribute :state, Symbol, :allowed => Orchestration::VALID_RESOURCE_STATES, :coerce => lambda { |v| v.to_sym }
        attribute :outputs, Output, :coerce => lambda { |v, stack| Output.new(stack, v) }, :multiple => true
        attribute :status, String
        attribute :status_reason, String
        attribute :created, Time, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
        attribute :updated, Time, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
        attribute :parameters, Smash, :coerce => lambda { |v| v.to_smash }
        attribute :template, Smash, :depends => :perform_template_load, :coerce => lambda { |v| v = MultiJson.load(v) if v.is_a?(String); v.to_smash }
        attribute :template_url, String
        attribute :template_description, String
        attribute :timeout_in_minutes, Integer
        attribute :tags, Smash, :coerce => lambda { |v| v.to_smash }, :default => Smash.new
        # TODO: This is new in AWS but I like this better for the
        # attribute. For now, keep both but i would like to deprecate
        # out the disable_rollback and provide the same functionality
        # via this attribute.
        attribute :on_failure, String, :allowed => %w(nothing rollback delete), :coerce => lambda { |v| v.to_s.downcase }
        attribute :disable_rollback, [TrueClass, FalseClass]
        attribute :notification_topics, String, :multiple => true
        attribute :capabilities, String, :multiple => true
        attribute :plan, Plan, :depends => :load_plan

        on_missing :reload

        # Overload the loader so we can extract resources,
        # events, and outputs
        def load_data(args = {})
          args = args.to_smash
          @resources = (args.delete(:resources) || []).each do |r|
            Resource.new(r)
          end
          @events = (args.delete(:events) || []).each do |e|
            Event.new(e)
          end
          super args
        end

        # Validate the stack template
        #
        # @return [TrueClass]
        # @raises [Miasma::Error::OrchestrationError::InvalidTemplate]
        def validate
          perform_template_validate
        end

        # Create a new stack plan
        #
        # @return [Plan]
        def plan_generate
          if plan
            raise Miasma::Error::OrchestrationError::StackPlanExists.new(
              "Plan already exists for this stack"
            )
          else
            perform_plan
          end
        end

        # Execute current execute
        #
        # @return [self]
        def plan_execute
          if dirty?(:plan)
            perform_plan_execute
          else
            raise Miasma::Error::OrchestrationError::InvalidStackPlan.new(
              "This stack instance does not have a generated plan"
            )
          end
        end

        # Delete the current plan
        #
        # @return [self]
        def plan_destroy
          if dirty?(:plan)
            perform_plan_destroy
          else
            raise Miasma::Error::OrchestrationError::InvalidStackPlan.new(
              "This stack instance does not have a generated plan"
            )
          end
        end

        # Override to scrub custom caches
        #
        # @return [self]
        def reload
          clear_memoizations!
          remove = data.keys.find_all do |k|
            ![:id, :name].include?(k.to_sym)
          end
          remove.each do |k|
            data.delete(k)
          end
          super
        end

        # @return [Events]
        def events
          memoize(:events) do
            Events.new(self)
          end
        end

        # @return [Plans]
        def plans
          memoize(:plans) do
            Plans.new(self)
          end
        end

        # @return [Resources]
        def resources
          memoize(:resources) do
            Resources.new(self)
          end
        end

        # Always perform save. Remove dirty check
        # provided by default.
        def save
          perform_save
        end

        protected

        # Stack is in valid state to generate plan
        #
        # @return [TrueClass, FalseClass]
        def planable?
          state.nil? || VALID_PLAN_STATES.include?(state)
        end

        # Proxy load plan action up to the API
        def load_plan
          memoize(:plan) do
            api.stack_plan_load(self)
          end
        end

        # Proxy plan action up to the API
        def perform_plan
          if planable?
            api.stack_plan(self)
          else
            raise Error::OrchestrationError::InvalidPlanState.new(
              "Stack state `#{state}` is not valid for plan generation"
            )
          end
        end

        # Proxy plan execute action up to the API
        def perform_plan_execute
          api.stack_plan_execute(self)
        end

        # Proxy plan delete action up to the API
        def perform_plan_destroy
          api.stack_plan_destroy(self)
        end

        # Proxy save action up to the API
        def perform_save
          api.stack_save(self)
        end

        # Proxy reload action up to the API
        def perform_reload
          api.stack_reload(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.stack_destroy(self)
        end

        # Proxy validate action up to API
        def perform_template_validate
          error = api.stack_template_validate(self)
          if error
            raise Error::OrchestrationError::InvalidTemplate.new(error)
          end
          true
        end

        # Proxy template loading up to the API
        def perform_template_load
          memoize(:template) do
            self.data[:template] = api.stack_template_load(self)
            true
          end
        end
      end
    end
  end
end
