require 'miasma'

module Miasma
  module Models
    class Orchestration
      # Abstract server
      class Stack < Types::Model

        # @return [Smash] mapping of remote type to internal type
        RESOURCE_MAPPING = Smash.new

        ## mapping example
        # RESOURCE_MAPPING = Smash.new(
        #   'AWS::EC2::Instance' => Miasma::Models::Compute::Server
        # )

        # Stack resource
        class Resource < Types::ThinModel

          attribute :name, String, :required => true
          attribute :type, String, :required => true
          attribute :logical_id, [String, Numeric]
          attribute :status, [String, Symbol], :required => true, :coerce => lambda{|v| v.to_s.to_sym}
          attribute :status_reason, String
          attribute :updated_time, Time
          attribute :links, Array

          attr_reader :stack

          def initalize(stack, args={})
            @stack = stack
            super stack.api, args
          end

          # @return [Miasma::Types::Model] provides mapped resource class
          def model
            # Insert provider to namespace
            provider_const = self.class.name.split('::').insert(3, Utils.camel(api.provider))
            # Remove current class
            provider_const.pop
            # Insert mapping constant name and fetch
            const = provider_const.push(:RESOURCE_MAPPING).inject(Object) do |memo, konst|
              res = memo.const_get(konst)
              break unless res
              res
            end
            if(const && const = const[self.type])
              # Now rebuild from the ground up
              const.to_s.split('::').insert(3, Utils.camel(api.provider)).inject(Object) do |memo, konst|
                memo.const_get(konst)
              end
            else
              raise KeyError.new "Failed to locate requested mapping! (`#{self.type}`)"
            end
          end

        end

        # Stack event
        class Event < Types::Data

          attribute :time, Time, :required => true
          attribute :resource_id, [String, Numeric], :required => true
          attribute :resource_logical_id, [String, Numeric]
          attribute :resource_name, String
          attribute :resource_status, String
          attribute :resource_status_reason, String

          attr_reader :stack

          def initialize(stack, args={})
            @stack = stack
            super stack.api, args
          end

          # @return [Resource]
          def resource
            stack.resources.detect do |r|
              r.id == self.resource_id
            end
          end

        end

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

        # @return [Array<Resource>]
        attr_reader :resources
        # @return [Array<Event>]
        attr_reader :events
        # @return [Array<Output>]
        attr_reader :outputs

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
