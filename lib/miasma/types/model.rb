require 'miasma'

module Miasma
  module Types

    # Base model
    class Model

      include Miasma::Utils::Lazy

      attribute :id, [String, Numeric]

      # @return [Miasma::Api] underlying service API
      attr_reader :api

      # Build new model
      #
      # @param api [Miasma::Api] service API
      # @param model_data [Smash] load model data if provided
      # @return [self]
      def initialize(api, model_data=nil)
        @api = api
        @data = Smash.new
        @dirty = Smash.new
        if(model_data)
          if(model_data.is_a?(Hash))
            load_data(model_data)
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
        unless(dirty.empty?)
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

      # Convert model to JSON string
      #
      # @return [String]
      def to_json
        MultiJson.dump(attributes)
      end

      # Load model using JSON string
      #
      # @param json [String]
      # @return [self]
      def from_json(json)
        set_attributes(
          MultiJson.load(json).to_smash
        )
      end

      # Reload the underlying data for model
      #
      # @return [self]
      def reload
        perform_reload
        self
      end

      # @return [TrueClass, FalseClass] model is persisted
      def persisted?
        id?
      end

    end

    protected

    # Save model state to remote API
    #
    # @return [TrueClass, FalseClass] performed remote action
    # @raises [Miasma::Error::Save]
    def perform_save
      raise NotImplemented.new 'Remote API save has not been implemented'
    end

    # Reload model state from remote API
    #
    # @return [TrueClass, FalseClass] performed remote action
    # @raises [Miasma::Error::Save]
    def perform_reload
      raise NotImplemented.new 'Remote API reload has not been implemented'
    end

    # Destroy model from remote API
    #
    # @return [TrueClass, FalseClass] performed remote action
    # @raises [Miasma::Error::Save]
    def perform_destroy
      raise NotImplemented.new 'Remote API destroy has not been implemented'
    end

  end
end
