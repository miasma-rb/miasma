require 'miasma'
require 'miasma/utils/smash'
require 'time'

class RackspaceApiCore

  AUTH_ENDPOINT = {
    :us => 'https://identity.api.rackspacecloud.com/v2.0',
    :uk => 'https://lon.identity.api.rackspacecloud.com/v2.0'
  }

  API_MAP = Smash.new(
    'compute' => 'cloudServersOpenStack'
  )

  attr_reader :user
  attr_reader :service_catalog
  attr_reader :token
  attr_reader :credentials

  def initialize(creds)
    @credentials = creds
  end

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

  def api_token
    if(token.nil? || Time.now > token[:expires])
      identify_and_load
    end
    token[:id]
  end

  def account_id
    if(token.nil? || Time.now > token[:expires])
      identify_and_load
    end
    token[:tenant][:id]
  end

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


module Miasma
  module Models
    class Compute
      class Rackspace < Compute

        attribute :rackspace_api_key, String, :required => true
        attribute :rackspace_username, String, :required => true
        attribute :rackspace_region, String, :required => true

        def connection
          HTTP.with_headers('X-Auth-Token' => token)
        end

        def endpoint
          rackspace_api.endpoint_for(:compute, rackspace_region)
        end

        def token
          rackspace_api.api_token
        end

        def rackspace_api
          memoize(:miasma_rackspace_api, :direct) do
            RackspaceApiCore.new(attributes)
          end
        end

        SERVER_STATE_MAP = {
          'ACTIVE' => :running,
          'DELETED' => :terminated,
          'SUSPENDED' => :stopped,
          'PASSWORD' => :running
        }

        def server_save(server)
          unless(server.persisted?)
            server.load_data(server.attributes)
            result = request(
              :expects => 202,
              :method => :post,
              :path => '/servers',
              :json => {
                :server => {
                  :flavorRef => server.flavor_id,
                  :name => server.name,
                  :imageRef => server.image_id,
                  :metadata => server.metadata,
                  :personality => server.personality,
                  :key_pair => server.key_name
                }
              }
            )
            server.id = result.get(:body, :server, :id)
          else
            raise "WAT DO I DO!?"
          end
        end

        def server_destroy(server)
          if(server.persisted?)
            result = request(
              :expects => 204,
              :method => :delete,
              :path => "/servers/#{server.id}"
            )
          else
            raise "this doesn't even exist"
          end
        end

        def server_change_state(server, state)
        end

        def server_reload(server)
          res = servers.reload
          node = res.detect do |s|
            s.id == server.id
          end
          if(node)
            server.load_data(node.data.dup)
            server.valid_state
          else
            server.data.clear
            server.dirty.clear
          end
        end

        def server_all
          result = request(
            :method => :get,
            :path => '/servers/detail'
          )
          result[:body].fetch(:servers, []).map do |srv|
            Server.new(
              self,
              :id => srv[:id],
              :name => srv[:name],
              :image_id => srv.get(:image, :id),
              :flavor_id => srv.get(:flavor, :id),
              :state => SERVER_STATE_MAP.fetch(srv[:status], :pending),
              :addresses_private => srv.fetch(:addresses, :private, []).map{|a|
                Server::Address.new(
                  :version => a[:version].to_i, :address => a[:addr]
                )
              },
              :addresses_public => srv.fetch(:addresses, :public, []).map{|a|
                Server::Address.new(
                  :version => a[:version].to_i, :address => a[:addr]
                )
              },
              :status => srv[:status],
              :key_name => srv[:key_name]
            ).valid_state
          end
        end

      end
    end
  end
end
