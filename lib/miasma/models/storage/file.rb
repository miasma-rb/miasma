require 'miasma'
require 'stringio'

module Miasma
  module Models
    class Storage

      # Abstract file
      class File < Types::Model

        attribute :name, String, :required => true
        attribute :body, IO, :coerce => lambda{|v| StringIO.new(v.to_s) }
        attribute :content_type, String
        attribute :content_disposition, String
        attribute :etag, String
        attribute :updated, Time, :coerce => lambda{|t| Time.parse(t.to_s)}
        attribute :size, Integer
        attribute :metadata, Smash, :coerce => lambda{|o| o.to_smash}

        # @return [Bucket] parent bucket
        attr_reader :bucket

        # Create a new instance
        #
        # @param bucket [Bucket]
        # @param args [Hash]
        # @return [self]
        def initialize(bucket, args={})
          @bucket = bucket
          super bucket.api, args
        end

        # Return files matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<File>]
        # @option options [String] :prefix key prefix
        def filter(options={})
          raise NotImplementedError
        end

      end

    end
  end
end
