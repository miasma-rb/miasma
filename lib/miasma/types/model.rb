require 'miasma'

module Miasma
  module Types

    # Base model
    class Model < Data

      include Utils::Memoization

      # @return [Miasma::Types::Api] underlying service API
      attr_reader :api

      class << self

        # Build new model from JSON
        #
        # @param api [Miasma::Types::Api]
        # @param json [String]
        # @return [Model]
        def from_json(api, json)
          instance = self.new(api)
          instance.from_json(json)
          instance
        end

      end

      # Build new model
      #
      # @param api [Miasma::Types::Api] service API
      # @param model_data [Smash] load model data if provided
      # @return [self]
      def initialize(api, model_data=nil)
        @api = api
        @data = Smash.new
        @dirty = Smash.new
        if(model_data)
          if(model_data.is_a?(Hash))
            load_data(model_data) unless model_data.empty?
          else
            raise TypeError.new "Expecting `model_data` to be of type `Hash`. Received: `#{model_data.class}`"
          end
        end
      end

      # Save changes to the model
      #
      # @return [TrueClass, FalseClass] save was performed
      # @raises [Miasma::Error::Save]
      def save
        if(dirty?)
          perform_save
          reload
        else
          false
        end
      end

      # Destroy the model
      #
      # @return [TrueClass, FalseClass] destruction was performed
      # @raises [Miasma::Error::Destroy]
      def destroy
        if(persisted?)
          perform_destroy
          reload
          true
        else
          false
        end
      end

      # Reload the underlying data for model
      #
      # @return [self]
      def reload
        clear_memoizations!
        perform_reload
        self
      end

      # @return [TrueClass, FalseClass] model is persisted
      def persisted?
        id?
      end

      # @return [String, Integer]
      def id?
        data[:id] || dirty[:id]
      end

      protected

      # Save model state to remote API
      #
      # @return [TrueClass, FalseClass] performed remote action
      # @raises [Miasma::Error::Save]
      def perform_save
        raise NotImplementedError.new 'Remote API save has not been implemented'
      end

      # Reload model state from remote API
      #
      # @return [TrueClass, FalseClass] performed remote action
      # @raises [Miasma::Error::Save]
      def perform_reload
        raise NotImplementedError.new 'Remote API reload has not been implemented'
      end

      # Destroy model from remote API
      #
      # @return [TrueClass, FalseClass] performed remote action
      # @raises [Miasma::Error::Save]
      def perform_destroy
        raise NotImplementedError.new 'Remote API destroy has not been implemented'
      end

    end
  end
end
