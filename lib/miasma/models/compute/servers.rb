require 'miasma'

module Miasma
  module Models
    class Compute

      # Abstract server collection
      class Servers < Types::Collection

        # Return servers matching given filter
        #
        # @param options [Hash] filter options
        # @option options [String] :state current instance state
        # @return [Array<Server>]
        def filter(options={})
          raise NotImplementedError
        end

        def build(args={})
          Server.new(api, args.to_smash)
        end

        # @return [Server] collection item class
        def model
          Server
        end

        protected

        # @return [Array<Server>]
        def perform_population
          api.server_all
        end

      end

    end
  end
end
