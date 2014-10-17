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

          include Utils::Immutable

        end

      end
    end
  end
end
