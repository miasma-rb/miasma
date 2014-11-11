require 'miasma'

module Miasma
  module Models
    class AutoScale

      # Abstract auto scale group collection
      class Groups < Types::Collection

        # Return auto scale groups matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<Group>]
        def filter(options={})
          raise NotImplementedError
        end

        # @return [Group] collection item class
        def model
          Group
        end

        protected

        # @return [Array<Group>]
        def perform_population
          api.group_all
        end

      end

    end
  end
end
