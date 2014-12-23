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
          unless(balancer.persisted?)
            params = Smash.new(
              'LoadBalancerName' => balancer.name
            )
            availability_zones.each_with_index do |az, i|
              params["AvailabilityZones.member.#{i+1}"] = az
            end
            if(balancer.listeners)
              balancer.listeners.each_with_index do |listener, i|
                key = "Listeners.member.#{i + 1}"
                params["#{key}.Protocol"] = listener.protocol
                params["#{key}.InstanceProtocol"] = listener.instance_protocol
                params["#{key}.LoadBalancerPort"] = listener.load_balancer_port
                params["#{key}.InstancePort"] = listener.instance_port
                if(listener.ssl_certificate_id)
                  params["#{key}.SSLCertificateId"] = listener.ssl_certificate_id
                end
              end
            end
            result = request(
              :path => '/',
              :params => params.merge(
                Smash.new(
                  'Action' => 'CreateLoadBalancer'
                )
              )
            )
            balancer.public_addresses = [
              :address => result.get(:body, 'CreateLoadBalancerResponse', 'CreateLoadBalancerResult', 'DNSName')
            ]
            balancer.load_data(:id => balancer.name).valid_state
            if(balancer.health_check)
              balancer_health_check(balancer)
            end
            if(balancer.servers && !balancer.servers.empty?)
              balancer_set_instances(balancer)
            end
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
          if(balancer.persisted?)
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
          result = all_result_pages(nil, :body, 'DescribeLoadBalancersResponse', 'DescribeLoadBalancersResult', 'LoadBalancerDescriptions', 'member') do |options|
            request(
              :path => '/',
              :params => options.merge(params)
            )
          end
          result.map do |blr|
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
          if(balancer.persisted?)
            request(
              :path => '/',
              :params => Smash.new(
                'Action' => 'DeleteLoadBalancer',
                'LoadBalancerName' => balancer.name
              )
            )
            balancer.state = :pending
            balancer.status = 'DELETE_IN_PROGRESS'
            balancer.valid_state
            true
          else
            false
          end
        end

        # Return all load balancers
        #
        # @param options [Hash] filter
        # @return [Array<Models::LoadBalancer::Balancer>]
        def balancer_all(options={})
          load_balancer_data
        end

        protected

        # @return [Array<String>] availability zones
        def availability_zones
          memoize(:availability_zones) do
            res = api_for(:compute).request(
              :path => '/',
              :params => Smash.new(
                'Action' => 'DescribeAvailabilityZones'
              )
            ).fetch(:body, 'DescribeAvailabilityZonesResponse', 'availabilityZoneInfo', 'item', [])
            [res].flatten.compact.map do |item|
              if(item['zoneState'] == 'available')
                item['zoneName']
              end
            end.compact
          end
        end

      end
    end
  end
end
