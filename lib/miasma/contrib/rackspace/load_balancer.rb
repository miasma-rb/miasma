require 'miasma'

module Miasma
  module Models
    class LoadBalancer
      class Rackspace < LoadBalancer

        include Contrib::OpenStackApiCore::ApiCommon
        include Contrib::RackspaceApiCore::ApiCommon

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
          if(balancer.persisted?)
            result = request(
              :path => "/loadbalancers/#{balancer.id}",
              :method => :get,
              :expects => 200
            )
            lb = result.get(:body, 'loadBalancer')
            balancer.load_data(
              :name => lb[:name],
              :name => lb[:name],
              :state => lb[:status] == 'ACTIVE' ? :active : :pending,
              :status => lb[:status],
              :created => lb.get(:created, :time),
              :updated => lb.get(:updated, :time),
              :public_addresses => lb['virtualIps'].map{|addr|
                if(addr[:type] == 'PUBLIC')
                  Balancer::Address.new(
                    :address => addr[:address],
                    :version => addr['ipVersion'].sub('IPV', '').to_i
                  )
                end
              }.compact,
              :private_addresses => lb['virtualIps'].map{|addr|
                if(addr[:type] != 'PUBLIC')
                  Balancer::Address.new(
                    :address => addr[:address],
                    :version => addr['ipVersion'].sub('IPV', '').to_i
                  )
                end
              }.compact,
              :servers => lb.fetch('nodes', []).map{|s|
                srv = self.api_for(:compute).servers.all.detect do |csrv|
                  csrv.addresses.map(&:address).include?(s[:address])
                end
                if(srv)
                  Balancer::Server.new(self.api_for(:compute), :id => srv.id)
                end
              }.compact
            ).valid_state
          else
            balancer
          end
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
          result = request(
            :path => '/loadbalancers',
            :method => :get,
            :expects => 200
          )
          result.fetch(:body, 'loadBalancers', []).map do |lb|
            Balancer.new(
              self,
              :id => lb[:id],
              :name => lb[:name],
              :state => lb[:status] == 'ACTIVE' ? :active : :pending,
              :status => lb[:status],
              :created => lb.get(:created, :time),
              :updated => lb.get(:updated, :time),
              :public_addresses => lb['virtualIps'].map{|addr|
                if(addr[:type] == 'PUBLIC')
                  Balancer::Address.new(
                    :address => addr[:address],
                    :version => addr['ipVersion'].sub('IPV', '').to_i
                  )
                end
              }.compact,
              :private_addresses => lb['virtualIps'].map{|addr|
                if(addr[:type] != 'PUBLIC')
                  Balancer::Address.new(
                    :address => addr[:address],
                    :version => addr['ipVersion'].sub('IPV', '').to_i
                  )
                end
              }.compact
            ).valid_state
          end
        end

      end
    end
  end
end
