require 'miasma'

module Miasma

  module Utils
    # Make best effort to make model immutable
    # @note this should be included at end of model definition
    module Immutable

      # Freezes underlying data hash
      def frozen_load_data(*args)
        unfrozen_load_data(*args)
        data.freeze
      end

      # @raises [Error::ImmutableError]
      def save
        raise Error::ImmutableError.new 'Resource information cannot be mutated!'
      end

      class << self

        def included(klass)
          klass.instance_methods.grep(/\w\=/).each do |method_name|
            klass.remove_method(method_name)
          end
          klass.class_eval do
            alias_method :unfrozen_load_data, :load_data
            alias_method :load_data, :frozen_load_data
          end
        end

      end

    end
  end
end
