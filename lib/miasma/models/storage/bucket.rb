require 'miasma'

module Miasma
  module Models
    class Storage
      # Abstract bucket
      class Bucket < Types::Model

        attribute :metadata, Hash, :coerce => lambda{|o| o.to_smash}

        # Filter buckets
        #
        # @param filter [Hash]
        # @return [Array<Bucket>]
        def filter(filter={})
        end

        # Rename bucket
        #
        # @param new_name [String]
        # @return [self]
        def rename(new_name)
          perform_rename(new_name)
        end

        protected

        def perform_rename(new_name)
          api.bucket_rename(self, new_name)
        end

      end

    end
  end
end
