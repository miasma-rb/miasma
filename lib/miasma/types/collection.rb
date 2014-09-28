require 'miasma'

module Miasma
  module Types

    # Base collection
    class Collection

      include Utils::Memoization

      # @return [Miasma::Api] underlying service API
      attr_reader :api

      def initialize(api)
        @api = api
        @collection = nil
      end

      # @return [Array<Model>]
      def all
        memoize(:collection) do
          perform_population
        end
      end

      # Reload the collection
      #
      # @return [Array<Model>]
      def reload
        unmemoize(:collection)
        all
      end

      # Return model with given name
      #
      # @param ident [String, Symbol] model identifier
      # @return [Model, NilClass]
      def get(ident)
        all.detect do |obj|
          obj.id == ident
        end
      end

      # Return models matching given filter
      #
      # @param args [Hash] filter options
      # @return [Array<Model>]
      def filter(args={})
        raise NotImplementedError
      end

      # Build a new model
      #
      # @param args [Hash] creation options
      # @return [Model]
      def build(args={})
        raise NotImplementedError
      end

      protected

      # @return [Array<Model>]
      def perform_population
        raise NotImplementedError
      end

    end
  end
end
