require 'miasma'
require 'miasma/contrib/open_stack'

module Miasma
  module Contrib

    # Rackspace API core helper
    class RackspaceApiCore < OpenStackApiCore

      # Authentication helper class
      class Authenticate < OpenStackApiCore::Authenticate
        # Authentication implementation compatible for v2
        class Version2 < OpenStackApiCore::Authenticate::Version2

          # @return [Smash] authentication request body
          def authentication_request
            Smash.new(
              'RAX-KSKEY:apiKeyCredentials' => Smash.new(
                'username' => credentials[:open_stack_username],
                'apiKey' => credentials[:open_stack_token]
              )
            )
          end

        end
      end

      # Common API methods
      module ApiCommon

        # Set attributes into model
        #
        # @param klass [Class]
        def self.included(klass)
          klass.attributes.clear

          klass.class_eval do
            attribute :rackspace_api_key, String, :required => true
            attribute :rackspace_username, String, :required => true
            attribute :rackspace_region, String, :required => true

            # @return [Miasma::Contrib::RackspaceApiCore]
            def open_stack_api
              key = "miasma_rackspace_api_#{attributes.checksum}".to_sym
              memoize(key, :direct) do
                Miasma::Contrib::RackspaceApiCore.new(attributes)
              end
            end

            # @return [String]
            def open_stack_region
              rackspace_region
            end

          end
        end


      end

      # @return [Smash] Authentication endpoints
      AUTH_ENDPOINT = Smash.new(
        :us => 'https://identity.api.rackspacecloud.com/v2.0',
        :uk => 'https://lon.identity.api.rackspacecloud.com/v2.0'
      )

      # @return [Smash] Mapping to external service name
      # @note ["cloudFilesCDN", "cloudFiles", "cloudBlockStorage",
      # "cloudImages", "cloudQueues", "cloudBigData",
      # "cloudOrchestration", "cloudServersOpenStack", "autoscale",
      # "cloudDatabases", "cloudBackup", "cloudMetrics",
      # "cloudLoadBalancers", "cloudNetworks", "cloudFeeds",
      # "cloudMonitoring", "cloudDNS"]

      API_MAP = Smash.new(
        'compute' => 'cloudServersOpenStack',
        'orchestration' => 'cloudOrchestration',
        'auto_scale' => 'autoscale',
        'load_balancer' => 'cloudLoadBalancers'
      )

      # Create a new api instance
      #
      # @param creds [Smash] credential hash
      # @return [self]
      def initialize(creds)
        if(creds[:rackspace_region].to_s == 'lon')
          endpoint = AUTH_ENDPOINT[:uk]
        else
          endpoint = AUTH_ENDPOINT[:us]
        end
        super Smash.new(
          :open_stack_username => creds[:rackspace_username],
          :open_stack_token => creds[:rackspace_api_key],
          :open_stack_region => creds[:rackspace_region],
          :open_stack_identity_url => endpoint
        )
      end

      # @return [String] ID of account
      def account_id
        identity.token[:tenant][:id]
      end

    end
  end

  Models::Compute.autoload :Rackspace, 'miasma/contrib/rackspace/compute'
  Models::Orchestration.autoload :Rackspace, 'miasma/contrib/rackspace/orchestration'
  Models::AutoScale.autoload :Rackspace, 'miasma/contrib/rackspace/auto_scale'
  Models::LoadBalancer.autoload :Rackspace, 'miasma/contrib/rackspace/load_balancer'
end
