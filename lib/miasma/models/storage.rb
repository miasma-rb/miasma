require 'miasma'

module Miasma
  module Models
    # Abstract storage API
    class Storage < Types::Api

      # Storage buckets
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::Storage::Bucket>] buckets
      def buckets(args={})
        Buckets.new(self)
      end

      # Create a new bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @return [Models::Storage::Bucket]
      def bucket_create(bucket)
        raise NotImplementedError
      end

      # Destroy bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @return [TrueClass, FalseClass]
      def bucket_delete(bucket)
        raise NotImplementedError
      end

      # Rename bucket
      #
      # @param bucket [Models::Storage::Bucket]
      # @param new_name [String]
      # @return [Models::Storage::Bucket] new bucket with updated name
      def bucket_rename(bucket, new_name)
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



    end
  end
end
