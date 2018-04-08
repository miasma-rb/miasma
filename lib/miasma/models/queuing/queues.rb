require "miasma"

module Miasma
  module Models
    class Queuing

      # Abstract queues collection
      class Queues < Types::Collection

        # Return queues matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<Queue>]
        def filter(options = {})
          raise NotImplementedError
        end

        # @return [Queue] collection item class
        def model
          Queue
        end

        protected

        # @return [Array<Queue>]
        def perform_population
          api.queue_all
        end
      end
    end
  end
end
