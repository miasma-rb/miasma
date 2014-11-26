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
          super
        end

        # @return [File] new unsaved instance
        def build(args={})
          instance = self.model.new(bucket)
          args.each do |m_name, m_value|
            m_name = "#{m_name}="
            instance.send(m_name, m_value)
          end
          instance
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

        # @return [Array<File>]
        def perform_filter(args)
          api.file_filter(bucket, args)
        end

      end

    end
  end
end
