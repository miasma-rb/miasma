require 'miasma'
require 'miasma/utils/smash'
require 'time'

module Miasma
  module Contrib

    # OpenStack API core helper
    class OpenStackApiCore

      class Authenticate

        # @return [Smash] token information
        attr_reader :token
        # @return [Smash] credentials in use
        attr_reader :credentials

        def initialize(credentials)
          @credentials = credentials.to_smash
        end

        # @return [String] username
        def user
          load!
          @user
        end

        # @return [Smash] remote service catalog
        def service_catalog
          load!
          @service_catalog
        end

        # @return [String] current API token
        def api_token
          if(token.nil? || Time.now > token[:expires])
            identify_and_load
          end
          token[:id]
        end

        # Identify with authentication endpoint
        # and load the service catalog
        #
        # @return [self]
        def identity_and_load
          raise NotImplementedError
        end

        protected

        # @return [TrueClass] load authenticator
        def load!
          !!api_token
        end

        class Version2 < Authenticate

          # Identify with authentication service and load
          # token information and service catalog
          #
          # @return [TrueClass]
          def identify_and_load
            if(credentials[:open_stack_token])
              auth = Smash.new(
                :token => Smash.new(
                  :id => credentials[:open_stack_token]
                )
              )
            else
              auth = Smash.new(
                'passwordCredentials' => Smash.new(
                  'username' => credentials[:open_stack_username],
                  'password' => credentials[:open_stack_password]
                )
              )
            end
            auth['tenantName'] = credentials[:open_stack_tenant_name]
            result = HTTP.post(File.join(credentials[:open_stack_identity_url], 'tokens'), :json => auth)
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

        class Version3 < Authenticate

          # Identify with authentication service and load
          # token information and service catalog
          #
          # @return [TrueClass]
          def identify_and_load
            ident = Smash.new(:methods => [])
            if(credentials[:open_stack_password])
              ident[:methods] << 'password'
              ident[:password] = Smash.new(
                :user => Smash.new(
                  :password => credentials[:open_stack_password]
                )
              )
              if(credentials[:open_stack_user_id])
                ident[:password][:user][:id] = credentials[:open_stack_user_id]
              else
                ident[:password][:user][:name] = credentials[:open_stack_username]
              end
              if(credentials[:open_stack_domain])
                ident[:password][:user][:domain] = Smash.new(
                  :name => credentials[:open_stack_domain]
                )
              end
            end
            if(credentials[:open_stack_token])
              ident[:methods] << 'token'
              ident[:token] = Smash.new(
                :token => Smash.new(
                  :id => credentials[:open_stack_token]
                )
              )
            end
            if(credentials[:open_stack_project_id])
              scope = Smash.new(
                :project => Smash.new(
                  :id => credentials[:open_stack_project_id]
                )
              )
            else
              if(credentials[:open_stack_domain])
                scope = Smash.new(
                  :domain => Smash.new(
                    :name => credentials[:open_stack_domain]
                  )
                )
                if(credentials[:open_stack_project])
                  scope[:project] = Smash.new(
                    :name => credentials[:open_stack_project]
                  )
                end
              end
            end
            auth = Smash.new(:identity => ident)
            if(scope)
              auth[:scope] = scope
            end
            result = HTTP.post(
              File.join(credentials[:open_stack_identity_url], 'tokens'),
              :json => Smash.new(
                :auth => auth
              )
            )
            info = MultiJson.load(result.body.to_s).to_smash[:token]
            @service_catalog = info.delete(:catalog)
            @token = Smash.new(
              :expires => Time.parse(info[:expires_at]),
              :id => result.headers['X-Subject-Token']
            )
            @user = info[:user][:name]
            true
          end

        end

      end

      module ApiCommon

        # Set attributes into model
        #
        # @param klass [Class]
        def self.included(klass)
          klass.class_eval do
            attribute :open_stack_identity_url, String, :required => true
            attribute :open_stack_username, String
            attribute :open_stack_user_id, String
            attribute :open_stack_password, String
            attribute :open_stack_token, String
            attribute :open_stack_region, String
            attribute :open_stack_tenant_name, String
            attribute :open_stack_domain, String
            attribute :open_stack_project, String
          end
        end

        # @return [HTTP] with auth token provided
        def connection
          super.with_headers('X-Auth-Token' => token)
        end

        # @return [String] endpoint URL
        def endpoint
          open_stack_api.endpoint_for(
            Utils.snake(self.class.to_s.split('::')[-2]).to_sym,
            open_stack_region
          )
        end

        # @return [String] valid API token
        def token
          open_stack_api.api_token
        end

        # @return [Miasma::Contrib::OpenStackApiCore]
        def open_stack_api
          key = "miasma_open_stack_api_#{attributes.checksum}".to_sym
          memoize(key, :direct) do
            Miasma::Contrib::OpenStackApiCore.new(attributes)
          end
        end

      end

      # @return [Smash] Mapping to external service name
      API_MAP = Smash.new(
        'compute' => 'nova',
        'orchestration' => 'heat',
        'network' => 'neutron',
        'identity' => 'keystone'
      )

      # @return [Miasma::Contrib::OpenStackApiCore::Authenticate]
      attr_reader :identity

      # Create a new api instance
      #
      # @param creds [Smash] credential hash
      # @return [self]
      def initialize(creds)
        @credentials = creds
        if(creds[:open_stack_identity_url].include?('v3'))
          @identity = Authenticate::Version3.new(creds)
        elsif(creds[:open_stack_identity_url].include?('v2'))
          @identity = Authenticate::Version2.new(creds)
        else
          # @todo allow attribute to override?
          raise ArgumentError.new('Failed to determine Identity service version')
        end
      end

      # Provide end point URL for service
      #
      # @param api_name [String] name of api
      # @param region [String] region in use
      # @return [String] public URL
      def endpoint_for(api_name, region)
        api = API_MAP[api_name]
        srv = identity.service_catalog.detect do |info|
          info[:name] == api
        end
        unless(srv)
          raise NotImplementedError.new("No API mapping found for `#{api_name}`")
        end
        if(region)
          point = srv[:endpoints].detect do |endpoint|
            endpoint[:region].to_s.downcase == region.to_s.downcase
          end
        else
          point = srv[:endpoints].first
        end
        if(point)
          point[:url]
        else
          raise KeyError.new("Lookup failed for `#{api_name}` within region `#{region}`")
        end
      end

      # @return [String] API token
      def api_token
        identity.api_token
      end

      # @return [String] ID of account
      def account_id
        identity.token[:tenant][:id]
      end


    end
  end

  Models::Compute.autoload :OpenStack, 'miasma/contrib/open_stack/compute'
end
