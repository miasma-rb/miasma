require 'miasma'

module Miasma
  module Models
    # Abstract storage API
    class Storage

      # Abstract bucket collection
      class Buckets < Types::Collection

        # @return [Bucket] new unsaved instance
        def build(args={})
          Bucket.new(api, args.to_smash)
        end

        # @return [Bucket] collection item class
        def model
          Bucket
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
