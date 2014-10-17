require 'miasma'

module Miasma

  module Utils
    # Make best effort to make model immutable
    # @note this should be included at end of model definition
    module Immutable

      # Freezes underlying data hash
      def frozen_valid_state(*args)
        unfrozen_valid_state(*args)
        data.freeze
        dirty.freeze
        self
      end

      # @raises [Error::ImmutableError]
      def save
        raise Error::ImmutableError.new 'Resource information cannot be mutated!'
      end

      class << self

        def included(klass)
          klass.class_eval do
            alias_method :unfrozen_valid_state, :valid_state
            alias_method :valid_state, :frozen_valid_state
          end
        end

      end

    end
  end
end
