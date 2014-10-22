require 'miasma'

module Miasma
  module Models
    # Abstract load balancer API
    class LoadBalancer < Types::Api

      autoload :Balancer, 'miasma/models/load_balancer/balancer'
      autoload :Balancers, 'miasma/models/load_balancer/balancers'

      # Load balancers
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::LoadBalancer::Balancer>] auto scale groups
      def balancers(filter={})
        memoize(:balancers) do
          Balancers.new(self)
        end
      end

      # Save load balancer
      #
      # @param balancer [Models::LoadBalancer::Balancer]
      # @return [Models::LoadBalancer::Balancer]
      def balancer_save(balancer)
        raise NotImplementedError
      end

      # Reload the balancer data from the API
      #
      # @param balancer [Models::LoadBalancer::Balancer]
      # @return [Models::LoadBalancer::Balancer]
      def balancer_reload(balancer)
        raise NotImplementedError
      end

      # Delete load balancer
      #
      # @param balancer [Models::LoadBalancer::Balancer]
      # @return [TrueClass, FalseClass]
      def balancer_destroy(balancer)
        raise NotImplementedError
      end

      # Return all load balancers
      #
      # @param options [Hash] filter
      # @return [Array<Models::LoadBalancer::Balancer>]
      def balancer_all(options={})
        raise NotImplementedError
      end

    end
  end
end
