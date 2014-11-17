require 'miasma'

module Miasma
  module Models
    class Compute
      class OpenStack < Compute

        include Contrib::OpenStackApiCore::ApiCommon

        # @return [Smash] map state to valid internal values
        SERVER_STATE_MAP = Smash.new(
          'ACTIVE' => :running,
          'DELETED' => :terminated,
          'SUSPENDED' => :stopped,
          'PASSWORD' => :running
        )

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
            true
          else
            false
          end
        end

        def server_change_state(server, state)
        end

        def server_reload(server)
          res = servers.reload.all
          node = res.detect do |s|
            s.id == server.id
          end
          if(node)
            server.load_data(node.data.dup)
            server.valid_state
          else
            server.data[:state] = :terminated
            server.dirty.clear
            server
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
