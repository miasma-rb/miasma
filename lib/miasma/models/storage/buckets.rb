require 'miasma'

module Miasma
  module Models
    # Abstract storage API
    class Storage

      # Abstract bucket collection
      class Buckets < Types::Collection

        # Return buckets matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<Bucket>]
        # @option options [String] :prefix key prefix
        def filter(options={})
          raise NotImplementedError
        end

        # @return [Array<Bucket>]
        def all
          api.bucket_all
        end

        # Create a new bucket
        #
        # @param args [Hash] creation options
        # @return [Bucket]
        def create
          api.bucket_create(self)
        end

      end

    end
  end
end
