require 'miasma'

module Miasma
  module Models
    class Orchestration
      # Abstract server
      class Stack < Types::Model

        autoload :Resource, 'miasma/models/orchestration/resource'
        autoload :Resources, 'miasma/models/orchestration/resources'
        autoload :Event, 'miasma/models/orchestration/event'
        autoload :Events, 'miasma/models/orchestration/events'

        include Miasma::Utils::Memoization

        # Stack output
        class Output < Types::Data

          attribute :key, String, :required => true
          attribute :value, String, :required => true
          attribute :description, String

          attr_reader :stack

          def initialize(stack, args={})
            @stack = stack
            super stack.api, args
          end

        end

        attribute :name, String, :required => true
        attribute :description, String
        attribute :state, [Symbol], :allowed => Orchestration::VALID_RESOURCE_STATES
        attribute :outputs, Array, :coerce => lambda{|v| v.map{|o| Output.new(o)}}
        attribute :status, [String]
        attribute :status_reason, String
        attribute :creation_time, Time
        attribute :updated_time, Time
        attribute :parameters, Hash
        attribute :template, Hash, :default => Smash.new, :depends => :perform_template_load
        attribute :template_url, String
        attribute :template_description, String
        attribute :timeout_in_minutes, Integer
        attribute :disable_rollback, [TrueClass, FalseClass]
        attribute :notification_topics, [String, Array]
        attribute :capabilities, Array

        on_missing :reload

        # Overload the loader so we can extract resources,
        # events, and outputs
        def load_data(args={})
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
          raise NotImplemented
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
