require 'miasma'

module Miasma

  module Models
    class Compute
      # Compute interface for AWS
      class Aws < Compute

        # Supported version of the EC2 API
        EC2_API_VERSION = '2014-06-15'

        # @return [Smash] map state to valid internal values
        SERVER_STATE_MAP = Smash.new(
          'running' => :running,
          'pending' => :pending,
          'shutting-down' => :pending,
          'terminated' => :terminated,
          'stopping' => :pending,
          'stopped' => :stopped
        )

        attribute :aws_access_key_id, String, :required => true
        attribute :aws_secret_access_key, String, :required => true
        attribute :aws_region, String, :required => true
        attribute :aws_host, String

        # @return [Contrib::AwsApiCore::SignatureV4]
        attr_reader :signer

        # Setup for API connections
        def connect
          unless(aws_host)
            self.aws_host = "ec2.#{aws_region}.amazonaws.com"
          end
          @signer = Contrib::AwsApiCore::SignatureV4.new(
            aws_access_key_id, aws_secret_access_key, aws_region, 'ec2'
          )
        end

        # @return [HTTP] connection for requests (forces headers)
        def connection
          super.with_headers(
            'Host' => aws_host,
            'X-Amz-Date' => Contrib::AwsApiCore.time_iso8601
          )
        end

        # @return [String] endpoint for request
        def endpoint
          "https://#{aws_host}"
        end

        # Override to inject signature
        #
        # @param connection [HTTP]
        # @param http_method [Symbol]
        # @param request_args [Array]
        # @return [HTTP::Response]
        def make_request(connection, http_method, request_args)
          dest, options = request_args
          path = URI.parse(dest).path
          options = options.to_smash
          options[:params] = options.fetch(:params, Smash.new).to_smash.deep_merge('Version' => EC2_API_VERSION)
          signature = signer.generate(
            http_method, path, options.merge(
              Smash.new(
                :headers => Smash[
                  connection.default_headers.to_a
                ]
              )
            )
          )
          options = Hash[options.map{|k,v|[k.to_sym,v]}]
          connection.auth(signature).send(http_method, dest, options)
        end

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
          result = request(
            :path => '/',
            :params => {
              'Action' => 'DescribeInstances'
            }
          )
          result.fetch(:body, 'DescribeInstancesResponse', 'reservationSet', 'item', []).map do |srv|
            srv = srv[:instancesSet][:item]
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
        end

      end
    end
  end

end
