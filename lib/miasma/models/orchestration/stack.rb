require 'miasma'

module Miasma
  module Models
    class Orchestration
      # Abstract server
      class Stack < Types::Model

        include Miasma::Utils::Memoization

        # @return [Smash] mapping of remote type to internal type
        RESOURCE_MAPPING = Smash.new

        ## mapping example
        # RESOURCE_MAPPING = Smash.new(
        #   'AWS::EC2::Instance' => Miasma::Models::Compute::Server
        # )

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
        attribute :status, [String, Symbol], :required => true, :coerce => lambda{|v| v.to_s.to_sym}
        attribute :status_reason, String
        attribute :creation_time, Time
        attribute :updated_time, Time
        attribute :parameters, Hash, :default => Smash.new
        attribute :template, Hash, :default => Smash.new
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
          @outputs = (args.delete(:outputs) || []).each do |o|
            Output.new(o)
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
      end

    end
  end
end
