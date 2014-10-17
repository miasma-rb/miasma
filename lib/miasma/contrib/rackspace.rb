require 'miasma'
require 'miasma/utils/smash'
require 'time'

module Miasma
  module Contrib

    # Rackspace API core helper
    class RackspaceApiCore

      module ModelCommon

        # Set attributes into model
        #
        # @param klass [Class]
        def self.included(klass)
          klass.class_eval do
            attribute :rackspace_api_key, String, :required => true
            attribute :rackspace_username, String, :required => true
            attribute :rackspace_region, String, :required => true
          end
        end

        # @return [HTTP] with auth token provided
        def connection
          super.with_headers('X-Auth-Token' => token)
        end

        # @return [String] endpoint URL
        def endpoint
          rackspace_api.endpoint_for(self.class.to_s.split('::')[-2].downcase.to_sym, rackspace_region)
        end

        # @return [String] valid API token
        def token
          rackspace_api.api_token
        end

        # @return [Miasma::Contrib::RackspaceApiCore]
        def rackspace_api
          memoize(:miasma_rackspace_api, :direct) do
            Miasma::Contrib::RackspaceApiCore.new(attributes)
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
        'orchestration' => 'cloudOrchestration'
      )

      # @return [String] username
      attr_reader :user
      # @return [Smash] remote service catalog
      attr_reader :service_catalog
      # @return [Smash] token information
      attr_reader :token
      # @return [Smash] credentials in use
      attr_reader :credentials

      # Create a new api instance
      #
      # @param creds [Smash] credential hash
      # @return [self]
      def initialize(creds)
        @credentials = creds
      end

      # Provide end point URL for service
      #
      # @param api_name [String] name of api
      # @param region [String] region in use
      # @return [String] public URL
      def endpoint_for(api_name, region)
        identify_and_load unless service_catalog
        api = API_MAP[api_name]
        srv = service_catalog.detect do |info|
          info[:name] == api
        end
        region = region.to_s.upcase
        point = srv[:endpoints].detect do |endpoint|
          endpoint[:region] == region
        end
        if(point)
          point[:publicURL]
        end
      end

      # @return [String] API token
      def api_token
        if(token.nil? || Time.now > token[:expires])
          identify_and_load
        end
        token[:id]
      end

      # @return [String] ID of account
      def account_id
        if(token.nil? || Time.now > token[:expires])
          identify_and_load
        end
        token[:tenant][:id]
      end

      # Identify with authentication service and load
      # token information and service catalog
      #
      # @return [TrueClass]
      def identify_and_load
        endpoint = credentials[:rackspace_region].to_s == 'lon' ? AUTH_ENDPOINT[:uk] : AUTH_ENDPOINT[:us]
        result = HTTP.post(File.join(endpoint, 'tokens'),
          :json => {
            'auth' => {
              'RAX-KSKEY:apiKeyCredentials' => {
                'username' => credentials[:rackspace_username],
                'apiKey' => credentials[:rackspace_api_key]
              }
            }
          }
        )
        unless(result.status == 200)
          raise Error::ApiError::AuthenticationError.new('Failed to authenticate', :response => result)
        end
        info = MultiJson.load(result.body.to_s).to_smash
        info = info[:access]
        @user = info[:user]
        @service_catalog = info[:serviceCatalog]
        @token = info[:token]
        token[:expires] = Time.parse(token[:expires])
        true
      end

    end
  end

  Models::Compute.autoload :Rackspace, 'miasma/contrib/rackspace/compute'
  Models::Orchestration.autoload :Rackspace, 'miasma/contrib/rackspace/orchestration'
end
