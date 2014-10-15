require 'miasma'

module Miasma
  module Models
    # Abstract compute API
    class Compute < Types::Api

      autoload :Server, 'miasma/models/compute/server'
      autoload :Servers, 'miasma/models/compute/servers'

      # Compute instances
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::Compute::Server>] servers
      def servers(filter={})
        memoize(:servers) do
          Servers.new(self)
        end
      end

      # Create new server instance
      #
      # @param server [Models::Compute::Server]
      # @return [Models::Compute::Server]
      def server_save(server)
        raise NotImplementedError
      end

      # Reload the server data from the API
      #
      # @param server [Models::Compute::Server]
      # @return [Models::Compute::Server]
      def server_reload(server)
        raise NotImplementedError
      end

      # Delete server instance
      #
      # @param server [Models::Compute::Server]
      # @return [TrueClass, FalseClass]
      def server_destroy(server)
        raise NotImplementedError
      end

      # Return all servers
      #
      # @param options [Hash] filter
      # @return [Array<Models::Compute::Server>]
      def server_all(options={})
        raise NotImplementedError
      end

      # Change server to desired state
      #
      # @param server [Models::Compute::Server]
      # @param action [Symbol] :start, :stop, :restart
      # @return [TrueClass, FalseClass]
      def server_change_state(server, action)
        raise NotImplementedError
      end

    end
  end
end
