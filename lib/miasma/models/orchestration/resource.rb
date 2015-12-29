require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Stack

        # Stack resource
        class Resource < Types::Model

          attribute :name, String, :required => true
          attribute :type, String, :required => true
          attribute :logical_id, [String, Numeric]
          attribute :state, Symbol, :required => true, :allowed_values => Orchestration::VALID_RESOURCE_STATES
          attribute :status, [String, Symbol], :required => true, :coerce => lambda{|v| v.to_s.to_sym}
          attribute :status_reason, String
          attribute :updated, Time, :coerce => lambda{|v| Time.parse(v.to_s)}

          on_missing :reload

          attr_reader :stack

          def initialize(stack, args={})
            @stack = stack
            super stack.api, args
          end

          # @return [Miasma::Types::Model] provides mapped resource class
          def dereference
            # Insert provider to namespace
            provider_const = self.class.name.split('::').insert(3, Utils.camel(api.provider))
            provider_const.slice!(-2, 2)
            # Insert mapping constant name and fetch
           const = provider_const.push(:RESOURCE_MAPPING).inject(Object) do |memo, konst|
              res = memo.const_get(konst)
              break unless res
              res
            end
            unless(const[self.type])
              raise KeyError.new "Failed to locate requested mapping! (`#{self.type}`)"
            end
            const[self.type]
          end

          # Provide proper instance from resource
          #
          # @return [Miasma::Types::Model]
          def expand
            info = dereference
            api.api_for(info[:api]).send(info[:collection]).get(self.id)
          end
          alias_method :instance, :expand

          # Proxy reload action up to the API
          def perform_reload
            api.resource_reload(self)
          end

          # Resource is within the collection on the api
          #
          # @param api [Symbol] api type (:compute, :auto_scale, etc)
          # @param collection [Symbol] collection within api (:servers, :groups, etc)
          # @return [TrueClass, FalseClass]
          def within?(api, collection)
            begin
              info = dereference
              info[:api] == api &&
                info[:collection] == collection
            rescue KeyError
              false
            end
          end

          include Utils::Immutable

        end

      end
    end
  end
end
