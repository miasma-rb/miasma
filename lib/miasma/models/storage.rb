require 'miasma'

module Miasma
  module Models
    # Abstract storage API
    class Storage < Types::Api

      # @return [Integer] max bytes allowed for storing body in string
      MAX_BODY_SIZE_FOR_STRINGIFY = 102400
      # @return [Integer] chunking size for reading IO
      READ_BODY_CHUNK_SIZE = 102400

      autoload :Buckets, 'miasma/models/storage/buckets'
      autoload :Bucket, 'miasma/models/storage/bucket'
      autoload :Files, 'miasma/models/storage/files'
      autoload :File, 'miasma/models/storage/file'

      # Storage buckets
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::Storage::Bucket>] buckets
      def buckets(args={})
        memoize(:buckets) do
          Buckets.new(self)
        end
      end

      # Save bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @return [Models::Storage::Bucket]
      def bucket_save(bucket)
        raise NotImplementedError
      end

      # Destroy bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @return [TrueClass, FalseClass]
      def bucket_destroy(bucket)
        raise NotImplementedError
      end

      # Reload the bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @return [Models::Storage::Bucket]
      def bucket_reload(bucket)
        raise NotImplementedError
      end

      # Return all buckets
      #
      # @return [Array<Models::Storage::Bucket>]
      def bucket_all
        raise NotImplementedError
      end

      # Return all files within bucket
      #
      # @param bucket [Bucket]
      # @return [Array<File>]
      def file_all(bucket)
        raise NotImplementedError
      end

      # Save file
      #
      # @param file [Models::Storage::File]
      # @return [Models::Storage::File]
      def file_save(file)
        raise NotImplementedError
      end

      # Destroy file
      #
      # @param file [Models::Storage::File]
      # @return [TrueClass, FalseClass]
      def file_destroy(file)
        raise NotImplementedError
      end

      # Reload the file
      #
      # @param file [Models::Storage::File]
      # @return [Models::Storage::File]
      def file_reload(file)
        raise NotImplementedError
      end

    end
  end
end
