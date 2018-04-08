require "miasma"

module Miasma
  module Types

    # Base data container
    class Data
      include Miasma::Utils::Lazy

      attribute :id, [String, Numeric]

      # Build new data instance
      #
      # @param args [Hash] attribute values
      # @return [self]
      def initialize(args = {})
        load_data(args)
        valid_state
      end

      # Convert model to JSON string
      #
      # @return [String]
      def to_json(*_)
        MultiJson.dump(attributes)
      end

      # Load model using JSON string
      #
      # @param json [String]
      # @return [self]
      def from_json(json)
        load_data(
          MultiJson.load(json).to_smash
        ).valid_state
      end

      class << self

        # Build new instance from JSON string
        #
        # @param json [String]
        # @return [Data]
        def from_json(json)
          self.new(MultiJson.load(json).to_smash)
        end
      end
    end
  end
end
