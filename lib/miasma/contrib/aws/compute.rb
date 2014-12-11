require 'miasma'

module Miasma

  module Models
    class Compute
      # Compute interface for AWS
      class Aws < Compute

        # Service name of the API
        API_SERVICE = 'ec2'
        # Supported version of the EC2 API
        API_VERSION = '2014-06-15'

        include Contrib::AwsApiCore::ApiCommon
        include Contrib::AwsApiCore::RequestUtils

        # @return [Smash] map state to valid internal values
        SERVER_STATE_MAP = Smash.new(
          'running' => :running,
          'pending' => :pending,
          'shutting-down' => :pending,
          'terminated' => :terminated,
          'stopping' => :pending,
          'stopped' => :stopped
        )

        # @todo catch bad lookup and clear model
        def server_reload(server)
          result = request(
            :path => '/',
            :params => {
              'Action' => 'DescribeInstances',
              'InstanceId.1' => server.id
            }
          )
          srv = result.get(:body, 'DescribeInstancesResponse', 'reservationSet', 'item', 'instancesSet', 'item')
          server.load_data(
            :id => srv[:instanceId],
            :name => srv.fetch(:tagSet, :item, []).map{|tag| tag[:value] if tag.is_a?(Hash) && tag[:key] == 'Name'}.compact.first,
            :image_id => srv[:imageId],
            :flavor_id => srv[:instanceType],
            :state => SERVER_STATE_MAP.fetch(srv.get(:instanceState, :name), :pending),
            :addresses_private => [Server::Address.new(:version => 4, :address => srv[:privateIpAddress])],
            :addresses_public => [Server::Address.new(:version => 4, :address => srv[:ipAddress])],
            :status => srv.get(:instanceState, :name),
            :key_name => srv[:keyName]
          )
          server.valid_state
        end

        def server_destroy(server)
          if(server.persisted?)
            result = request(
              :path => '/',
              :params => {
                'Action' => 'TerminateInstances',
                'InstanceId.1' => server.id
              }
            )
          else
            raise "this doesn't even exist"
          end
        end

        def server_save(server)
          unless(server.persisted?)
            server.load_data(server.attributes)
            result = request(
              :path => '/',
              :params => {
                'Action' => 'RunInstances',
                'ImageId' => server.image_id,
                'InstanceType' => server.flavor_id,
                'KeyName' => server.key_name,
                'MinCount' => 1,
                'MaxCount' => 1
              }
            )
            server.id = result.get(:body, 'RunInstancesResponse', 'instancesSet', 'item', 'instanceId')
          else
            raise 'WAT DO I DO!?'
          end
        end

        # @todo need to add auto pagination helper (as common util)
        def server_all
          results = all_result_pages(nil, :body, 'DescribeInstancesResponse', 'reservationSet', 'item') do |options|
            request(:path => '/', :params => options.merge('Action' => 'DescribeInstances'))
          end
          results.map do |srv|
            [srv[:instancesSet][:item]].flatten.compact.map do |srv|
              Server.new(
                self,
                :id => srv[:instanceId],
                :name => srv.fetch(:tagSet, :item, []).map{|tag| tag[:value] if tag.is_a?(Hash) && tag[:key] == 'Name'}.compact.first,
                :image_id => srv[:imageId],
                :flavor_id => srv[:instanceType],
                :state => SERVER_STATE_MAP.fetch(srv.get(:instanceState, :name), :pending),
                :addresses_private => [Server::Address.new(:version => 4, :address => srv[:privateIpAddress])],
                :addresses_public => [Server::Address.new(:version => 4, :address => srv[:ipAddress])],
                :status => srv.get(:instanceState, :name),
                :key_name => srv[:keyName]
              ).valid_state
            end
          end.flatten
        end

      end
    end
  end

end
