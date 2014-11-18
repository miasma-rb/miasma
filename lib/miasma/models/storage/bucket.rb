require 'miasma'

module Miasma
  module Models
    class Storage
      # Abstract bucket
      class Bucket < Types::Model

        attribute :name, String, :required => true
        attribute :created, Time, :coerce => lambda{|t| Time.parse(t.to_s)}
        attribute :metadata, Smash, :coerce => lambda{|o| o.to_smash}

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
        def filter(filter={})
          raise NotImplementedError
        end

      end

    end
  end
end
