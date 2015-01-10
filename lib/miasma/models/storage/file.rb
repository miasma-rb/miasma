require 'miasma'
require 'stringio'

module Miasma
  module Models
    class Storage

      # Abstract file
      class File < Types::Model

        # Simple wrapper to keep consistent reading behavior
        class Streamable

          # @return [Object] IO-ish thing
          attr_reader :io

          def initialize(io_item)
            unless(io_item.respond_to?(:readpartial))
              raise TypeError.new 'Instance must respond to `#readpartial`'
            end
            @io = io_item
          end

          # Proxy missing methods to io
          def method_missing(method_name, *args, &block)
            if(io.respond_to?(method_name))
              io.send(method_name, *args, &block)
            else
              raise
            end
          end

          # Customized readpartial to automatically hand EOF
          #
          # @param length [Integer] length to read
          # @return [String]
          def readpartial(length=nil)
            begin
              io.readpartial(length)
            rescue EOFError
              nil
            end
          end

        end

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
            data[:body] = api.file_body(self)
          end
          attributes[:body]
        end

        # Set file body
        #
        # @param io [IO, String]
        # @return [IO]
        def body=(io)
          unless(io.respond_to?(:readpartial))
            io = StringIO.new(io)
          end
          dirty[:body] = io
        end

        # Create accessible URL
        #
        # @param timeout_in_seconds [Integer] optional if private (default: 60)
        # @return [String] URL
        def url(timeout_in_seconds=60)
          perform_file_url(timeout_in_seconds)
        end

        # Destroy file
        #
        # @return [self]
        def destroy
          perform_destroy
          data.clear
          dirty.clear
          self
        end

        protected

        # Proxy URL action up to the API
        def perform_file_url(secs)
          api.file_url(self, secs)
        end

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
