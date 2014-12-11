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
      # @return [self]
      def reload
        clear_memoizations!
        self
      end

      # Return model with given name or ID
      #
      # @param ident [String, Symbol] model identifier
      # @return [Model, NilClass]
      def get(ident)
        memoize(ident) do
          perform_get(ident)
        end
      end

      # Return models matching given filter
      #
      # @param args [Hash] filter options
      # @return [Array<Model>]
      # @todo need to add helper to deep sort args, convert to string
      #   and hash to use as memoization key
      def filter(args={})
        key = "filter_#{args.to_smash.checksum}"
        memoize(key) do
          perform_filter(args)
        end
      end

      # Build a new model
      #
      # @param args [Hash] creation options
      # @return [Model]
      def build(args={})
        instance = self.model.new(self.api)
        args.each do |m_name, m_value|
          m_name = "#{m_name}="
          instance.send(m_name, m_value)
        end
        instance
      end

      # @return [String] collection of models
      def to_json(*_)
        self.all.to_json
      end

      # Load collection via JSON
      #
      # @param json [String]
      # @return [self]
      def from_json(json)
        loaded = MultiJson.load(json)
        unless(loaded.is_a?(Array))
          raise TypeError.new "Expecting type `Array` but received `#{loaded.class}`"
        end
        unmemoize(:collection)
        memoize(:collection) do
          loaded.map do |item|
            model.from_json(self.api, MultiJson.dump(item))
          end
        end
        self
      end

      # @return [Miasma::Types::Model] model class within collection
      def model
        raise NotImplementedError
      end

      protected

      # Return model with given name or ID
      #
      # @param ident [String, Symbol] model identifier
      # @return [Model, NilClass]
      def perform_get(ident)
        i = model.new(api)
        i.id = ident
        begin
          i.reload
        rescue Error::ApiError::RequestError => e
          if(e.code == 404)
            nil
          else
            raise
          end
        end
      end

      # @return [Array<Model>]
      def perform_population
        raise NotImplementedError
      end

      # @return [Array<Model>]
      def perform_filter(args)
        if(args[:prefix])
          all.find_all do |item|
            item.name.start_with?(args[:prefix])
          end
        else
          all
        end
      end

    end
  end
end
