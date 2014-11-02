require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Aws < Orchestration

        # Service name of the API
        API_SERVICE = 'cloudformation'
        # Supported version of the AutoScaling API
        API_VERSION = '2010-05-15'

        # Valid stack lookup states
        STACK_STATES = [
          "CREATE_COMPLETE", "CREATE_FAILED", "CREATE_IN_PROGRESS", "DELETE_FAILED",
          "DELETE_IN_PROGRESS", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "ROLLBACK_IN_PROGRESS",
          "UPDATE_COMPLETE", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS", "UPDATE_IN_PROGRESS",
          "UPDATE_ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS", "UPDATE_ROLLBACK_FAILED",
          "UPDATE_ROLLBACK_IN_PROGRESS"
        ]

        include Contrib::AwsApiCore::ApiCommon
        include Contrib::AwsApiCore::RequestUtils

        # @return [Smash] external to internal resource mapping
        RESOURCE_MAPPING = Smash.new(
          'AWS::EC2::Instance' => Smash.new(
            :api => :compute,
            :collection => :servers
          ),
          'AWS::ElasticLoadBalancing::LoadBalancer' => Smash.new(
            :api => :auto_scale,
            :collection => :groups
          )
        )

        # Fetch stacks or update provided stack data
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Array<Models::Orchestration::Stack>]
        def load_stack_data(stack=nil)
          d_params = Smash.new('Action' => 'DescribeStacks')
          l_params = Smash.new('Action' => 'ListStacks')
          STACK_STATES.each_with_index do |state, idx|
            l_params["StackStatusFilter.member.#{idx + 1}"] = state.to_s.upcase
          end
          if(stack)
            d_params['StackName'] = stack.id
          end
          descriptions = [
            request(:path => '/', :params => d_params).get(
              :body, 'DescribeStacksResult', 'Stacks', 'member'
            )
          ].flatten(1).compact
          lists = request(:path => '/', :params => l_params)
          [
            lists.get(
              :body, 'ListStacksResponse', 'ListStacksResult',
              'StackSummaries', 'member'
            )
          ].flatten(1).compact.map do |stk|
            desc = descriptions.detect do |d_stk|
              d_stk['StackId'] == stk['StackId']
            end || Smash.new
            stk.merge!(desc)
            puts "STK: #{stk.inspect}"
            new_stack = stack || Stack.new(self)
            new_stack.load_data(
              :id => stk['StackId'],
              :name => stk['StackName'],
              :capabilities => stk.fetch('Capabilities', []).compact,
              :description => stk['Description'],
              :creation_time => stk['CreationTime'],
              :updated_time => stk['LastUpdatedTime'],
              :notification_topics => stk.fetch('NotificationARNs', []).compact,
              :timeout_in_minutes => stk['TimeoutInMinutes'],
              :status => stk['StackStatus'],
              :status_reason => stk['StackStatusReason'],
              :state => stk['StackStatus'].downcase.to_sym,
              :template_description => stk['TemplateDescription'],
              :disable_rollback => !!stk['DisableRollback'],
              :outputs => [stk.fetch('Outputs', 'member', [])].flatten(1).map{|o|
                Smash.new(
                  :key => o['OutputKey'],
                  :value => o['OutputValue'],
                  :description => o['Description']
                )
              },
              :parameters => Smash[
                [stk.fetch('Parameters', 'member', [])].flatten(1).map{|param|
                  [param['ParameterKey'], param['ParameterValue']]
                }
              ]
            ).valid_state
          end
        end

        # Save the stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Models::Orchestration::Stack]
        def stack_save(stack)
          if(stack.persisted?)
          else
          end
        end

        # Reload the stack data from the API
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Models::Orchestration::Stack]
        def stack_reload(stack)
          if(stack.persisted?)
            load_stack_data(stack)
          end
          stack
        end

        # Delete the stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [TrueClass, FalseClass]
        def stack_destroy(stack)
          if(stack.persisted?)
            request(
              :path => '/',
              :params => Smash.new(
                'Action' => 'DeleteStack',
                'StackName' => stack.id
              )
            )
            true
          else
            false
          end
        end

        # Fetch stack template
        #
        # @param stack [Stack]
        # @return [Smash] stack template
        def stack_template_load(stack)
          if(stack.persisted?)
            result = request(
              :path => '/',
              :params => Smash.new(
                'Action' => 'GetTemplate',
                'StackName' => stack.id
              )
            )
            MultiJson.load(
              result.fetch(:body, 'GetTemplateResult', 'TemplateBody')
            ).to_smash
          else
            Smash.new
          end
        end

        # Return all stacks
        #
        # @param options [Hash] filter
        # @return [Array<Models::Orchestration::Stack>]
        # @todo check if we need any mappings on state set
        def stack_all
          load_stack_data
        end

        # Return all resources for stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Array<Models::Orchestration::Stack::Resource>]
        def resource_all(stack)
          result = request(
            :path => '/',
            :params => Smash.new(
              'Action' => 'DescribeStackResources',
              'StackName' => stack.id
            )
          )
          [
            result.fetch(
              :body, 'DescribeStackResourcesResult',
              'StackResources', 'member', []
            )
          ].flatten(1).compact.map do |res|
            Stack::Resource.new(
              stack,
              :id => res['PhysicalResourceId'],
              :logical_id => res['LogicalResourceId'],
              :type => res['ResourceType'],
              :state => res['ResourceStatus'].downcase.to_sym,
              :status => res['ResourceStatus'],
              :status_reason => res['ResourceStatusReason'],
              :updated_time => res['Timestamp']
            ).valid_state
          end
        end

        # Reload the stack resource data from the API
        #
        # @param resource [Models::Orchestration::Stack::Resource]
        # @return [Models::Orchestration::Resource]
        def resource_reload(resource)
          resource.stack.resources.reload
          resource.stack.resources.get(resource.id)
        end

        # Return all events for stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Array<Models::Orchestration::Stack::Event>]
        def event_all(stack, evt_id=nil)
          results = all_result_pages(nil, :body, 'DescribeStackEventsResult', 'StackEvents', 'member') do |options|
            request(
              :path => '/',
              :params => options.merge(
                'Action' => 'DescribeStackEvents',
                'StackName' => stack.id
              )
            )
          end
          events = results.map do |event|
            Stack::Event.new(
              stack,
              :id => event['EventId'],
              :resource_id => event['PhysicalResourceId'],
              :resource_name => event['LogicalResourceId'],
              :resource_logical_id => event['LogicalResourceId'],
              :resource_state => event['ResourceStatus'].downcase.to_sym,
              :resource_status => event['ResourceStatus'],
              :resource_status_reason => event['ResourceStatusReason'],
              :time => Time.parse(event['Timestamp'])
            ).valid_state
          end
          if(evt_id)
            idx = events.index{|d| e.id == evt_id}
            idx = idx ? idx + 1 : 0
            events.slice(idx, events.size)
          else
            events
          end
        end

        # Return all new events for event collection
        #
        # @param events [Models::Orchestration::Stack::Events]
        # @return [Array<Models::Orchestration::Stack::Event>]
        def event_all_new(events)
          event_all(events.stack, events.all.first.id)
        end

        # Reload the stack event data from the API
        #
        # @param resource [Models::Orchestration::Stack::Event]
        # @return [Models::Orchestration::Event]
        def event_reload(event)
          event.stack.events.reload
          event.stack.events.get(event.id)
        end

      end
    end
  end
end
