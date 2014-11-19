require 'miasma'
require 'stringio'

module Miasma
  module Models
    class Storage

      # Abstract file
      class File < Types::Model

        attribute :name, String, :required => true
        attribute :content_type, String
        attribute :content_disposition, String
        attribute :content_encoding, String
        attribute :etag, String
        attribute :updated, Time, :coerce => lambda{|t| Time.parse(t.to_s)}
        attribute :size, Integer
        attribute :metadata, Smash, :coerce => lambda{|o| o.to_smash}

        on_missing :reload

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

        # @return [IO-ish]
        # @note object returned will provide #readpartial
        def body
          unless(attributes[:body])
            data[:body] ||= api.file_body(self)
          end
          attributes[:body]
        end

        # Set file body
        #
        # @param io [IO, String]
        # @return [IO]
        def body=(io)
          unless(io.is_a?(IO))
            io = StringIO.new(io)
          end
          dirty[:body] = io
        end

        protected

        # Proxy reload action up to the API
        def perform_reload
          api.file_reload(self)
        end

        # Proxy save action up to the API
        def perform_save
          api.file_save(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.file_destroy(self)
        end

      end

    end
  end
end
