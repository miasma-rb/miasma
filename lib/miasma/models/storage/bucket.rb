require "miasma"

module Miasma
  module Models
    class Storage
      # Abstract bucket
      class Bucket < Types::Model
        attribute :name, String, :required => true
        attribute :created, Time, :coerce => lambda { |t| Time.parse(t.to_s).localtime }
        attribute :metadata, Smash, :coerce => lambda { |o| o.to_smash }

        # @return [Files]
        def files
          memoize(:files) do
            Files.new(self)
          end
        end

        # Filter buckets
        #
        # @param filter [Hash]
        # @return [Array<Bucket>]
        def filter(filter = {})
          raise NotImplementedError
        end

        protected

        # Proxy reload action up to the API
        def perform_reload
          api.bucket_reload(self)
        end

        # Proxy save action up to the API
        def perform_save
          api.bucket_save(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.bucket_destroy(self)
        end
      end
    end
  end
end
