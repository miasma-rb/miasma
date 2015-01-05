require 'miasma'
require 'miasma/utils/smash'
require 'time'

module Miasma
  module Contrib

    # OpenStack API core helper
    class OpenStackApiCore

      # Authentication helper class
      class Authenticate

        # @return [Smash] token info
        attr_reader :token
        # @return [Smash] credentials in use
        attr_reader :credentials

        # Create new instance
        #
        # @return [self]
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

        # @return [Smash] authentication request body
        def authentication_request
          raise NotImplementedError
        end

        protected

        # @return [TrueClass] load authenticator
        def load!
          !!api_token
        end

        # Authentication implementation compatible for v2
        class Version2 < Authenticate

          # @return [Smash] authentication request body
          def authentication_request
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
            if(credentials[:open_stack_tenant_name])
              auth['tenantName'] = credentials[:open_stack_tenant_name]
            end
            auth
          end

          # Identify with authentication service and load
          # token information and service catalog
          #
          # @return [TrueClass]
          def identify_and_load
            result = HTTP.post(
              File.join(
                credentials[:open_stack_identity_url],
                'tokens'
              ),
              :json => Smash.new(
                :auth => authentication_request
              )
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

        # Authentication implementation compatible for v2
        class Version3 < Authenticate

          # @return [Smash] authentication request body
          def authentication_request
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
            auth
          end

          # Identify with authentication service and load
          # token information and service catalog
          #
          # @return [TrueClass]
          def identify_and_load
            result = HTTP.post(
              File.join(credentials[:open_stack_identity_url], 'tokens'),
              :json => Smash.new(
                :auth => authentication_request
              )
            )
            unless(result.status == 200)
              raise Error::ApiError::AuthenticationError.new('Failed to authenticate!', result)
            end
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

      # Common API methods
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
        'identity' => 'keystone',
        'storage' => 'swift'
      )

      include Miasma::Utils::Memoization

      # @return [Miasma::Contrib::OpenStackApiCore::Authenticate]
      attr_reader :identity

      # Create a new api instance
      #
      # @param creds [Smash] credential hash
      # @return [self]
      def initialize(creds)
        @credentials = creds
        memo_key = "miasma_open_stack_identity_#{creds.checksum}"
        if(creds[:open_stack_identity_url].include?('v3'))
          @identity = memoize(memo_key, :direct) do
            identity_class('Authenticate::Version3').new(creds)
          end
        elsif(creds[:open_stack_identity_url].include?('v2'))
          @identity = memoize(memo_key, :direct) do
            identity_class('Authenticate::Version2').new(creds)
          end
        else
          # @todo allow attribute to override?
          raise ArgumentError.new('Failed to determine Identity service version')
        end
      end

      # @return [Class] class from instance class, falls back to parent
      def identity_class(i_name)
        [self.class, Miasma::Contrib::OpenStackApiCore].map do |klass|
          i_name.split('::').inject(klass) do |memo, key|
            if(memo.const_defined?(key))
              memo.const_get(key)
            else
              break
            end
          end
        end.compact.first
      end

      # Provide end point URL for service
      #
      # @param api_name [String] name of api
      # @param region [String] region in use
      # @return [String] public URL
      def endpoint_for(api_name, region)
        api = self.class.const_get(:API_MAP)[api_name]
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
          point.fetch(
            :publicURL,
            point[:url]
          )
        else
          raise KeyError.new("Lookup failed for `#{api_name}` within region `#{region}`")
        end
      end

      # @return [String] API token
      def api_token
        identity.api_token
      end

    end
  end

  Models::Compute.autoload :OpenStack, 'miasma/contrib/open_stack/compute'
  Models::Orchestration.autoload :OpenStack, 'miasma/contrib/open_stack/orchestration'
  Models::Storage.autoload :OpenStack, 'miasma/contrib/open_stack/storage'
end
