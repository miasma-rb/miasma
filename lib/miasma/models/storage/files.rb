require 'miasma'

module Miasma
  module Models
    class Storage

      # Abstract file collection
      class Files < Types::Collection

        # @return [Bucket] parent bucket
        attr_reader :bucket

        # Create new instance
        #
        # @param bucket [Bucket] parent bucket
        # @return [self]
        def initialize(bucket)
          @bucket = bucket
          super bucket.api
        end

        # Return files matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<File>]
        # @option options [String] :prefix key prefix
        def filter(options={})
          raise NotImplementedError
        end

        # @return [File] new unsaved instance
        def build(args={})
          File.new(api, args.to_smash)
        end

        # @return [File] collection item class
        def model
          File
        end

        protected

        # @return [Array<File>]
        def perform_population
          api.file_all(bucket)
        end

      end

    end
  end
end
