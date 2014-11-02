require 'miasma'

module Miasma
  module Models
    class LoadBalancer
      class Aws < LoadBalancer

        include Contrib::AwsApiCore::ApiCommon
        include Contrib::AwsApiCore::RequestUtils

        # Service name of API
        API_SERVICE = 'elasticloadbalancing'
        # Supported version of the ELB API
        API_VERSION = '2012-06-01'

        # Save load balancer
        #
        # @param balancer [Models::LoadBalancer::Balancer]
        # @return [Models::LoadBalancer::Balancer]
        def balancer_save(balancer)
          unless(persisted?)
            params = Smash.new('LoadBalancerName' => balancer.name)
            if(balancer.listeners)
              balancer.listeners.each_with_index do |listener, i|
                key = "Listeners.member.#{i + 1}"
                params[key] = Smash.new(
                  'Protocol' => listener.protocol,
                  'InstanceProtocol' => listener.instance_protocol,
                  'LoadBalancerPort' => listener.load_balancer_port,
                  'InstancePort' => listener.instance_port
                )
                if(listener.ssl_certificate_id)
                  params[key] = listener.ssl_certificate_id
                end
              end
            end
            result = request(
              :path => '/',
              :params => params
            )
            balancer.address = result.get(
              :body, 'CreateLoadBalancerResponse', 'CreateLoadBalancerResult', 'DNSName'
            )
            if(balancer.health_check)
              balancer_health_check(balancer)
            end
            if(balancer.servers && !balancer.servers.empty?)
              balancer_set_instances(balancer)
            end
            balancer.load_data(:id => balancer.name).valid_state
          else
            if(balancer.dirty?)
              if(balancer.dirty?(:health_check))
                balancer_health_check(balancer)
              end
              if(balancer.dirty?(:servers))
                balancer_set_instances(balancer)
              end
              balancer.reload
            end
            balancer
          end
        end

        # Save the load balancer health check
        #
        # @param balancer [Models::LoadBalancer::Balancer]
        # @return [Models::LoadBalancer::Balancer]
        def balancer_health_check(balancer)
          balancer
        end

        # Save the load balancer attached servers
        #
        # @param balancer [Models::LoadBalancer::Balancer]
        # @return [Models::LoadBalancer::Balancer]
        def balancer_set_instances(balancer)
          balancer
        end

        # Reload the balancer data from the API
        #
        # @param balancer [Models::LoadBalancer::Balancer]
        # @return [Models::LoadBalancer::Balancer]
        def balancer_reload(balancer)
          if(balancer.id)
            load_balancer_data(balancer)
          end
          balancer
        end

        # Fetch balancers or update provided balancer data
        #
        # @param balancer [Models::LoadBalancer::Balancer]
        # @return [Array<Models::LoadBalancer::Balancer>]
        def load_balancer_data(balancer=nil)
          params = Smash.new('Action' => 'DescribeLoadBalancers')
          if(balancer)
            params.merge('LoadBalancerNames.member.1' => balancer.id || balancer.name)
          end
          result = request(
            :path => '/',
            :params => params
          )
          [result.get(:body, 'DescribeLoadBalancersResponse', 'DescribeLoadBalancersResult', 'LoadBalancerDescriptions', 'member')].flatten(1).map do |blr|
            (balancer || Balancer.new(self)).load_data(
              :id => blr['LoadBalancerName'],
              :name => blr['LoadBalancerName'],
              :state => :active,
              :status => 'ACTIVE',
              :created => blr['CreatedTime'],
              :updated => blr['CreatedTime'],
              :public_addresses => [
                Balancer::Address.new(
                  :address => blr['DNSName'],
                  :version => 4
                )
              ],
              :servers => [blr.get('Instances', 'member')].flatten(1).compact.map{|i|
                Balancer::Server.new(self.api_for(:compute), :id => i['InstanceId'])
              }
            ).valid_state
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
          load_balancer_data
        end

      end
    end
  end
end
