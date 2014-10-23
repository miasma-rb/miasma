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

        # @return [Bucket] new unsaved instance
        def build(args={})
          Bucket.new(api, args.to_smash)
        end

        protected

        # @return [Array<Bucket>]
        def perform_population
          api.bucket_all
        end

      end

    end
  end
end
