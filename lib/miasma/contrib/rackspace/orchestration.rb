require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Rackspace < Orchestration

        include Contrib::RackspaceApiCore::ModelCommon

        # @return [Smash] external to internal resource mapping
        RESOURCE_MAPPING = Smash.new(
          'Rackspace::Cloud::Server' => Smash.new(
            :api => :compute,
            :collection => :servers
          )
        )

        # Save the stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Models::Orchestration::Stack]
        def stack_save(stack)
          raise NotImplementedError
          if(stack.persisted?)
          else
          end
        end

        # Reload the stack data from the API
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Models::Orchestration::Stack]
        def stack_reload(stack)
          result = request(
            :method => :get,
            :path => "/stacks/#{stack.name}/#{stack.id}",
            :expects => 200
          )
          stk = result.get(:body, :stack)
          stack.load_data(
            :id => stk[:id],
            :capabilities => stk[:capabilities],
            :creation_time => Time.parse(stk[:creation_time]),
            :description => stk[:description],
            :disable_rollback => stk[:disable_rollback].to_s.downcase == 'true',
            :notification_topics => stk[:notification_topics],
            :name => stk[:stack_name],
            :state => stk[:stack_status].downcase.to_sym,
            :status => stk[:stack_status],
            :status_reason => stk[:stack_status_reason],
            :template_description => stk[:template_description],
            :timeout_in_minutes => stk[:timeout_mins].to_s.empty? ? nil : stk[:timeout_mins].to_i,
            :updated_time => stk[:updated_time].to_s.empty? ? nil : Time.parse(stk[:updated_time]),
            :parameters => stk.fetch(:parameters, Smash.new),
            :outputs => stk.fetch(:outputs, []).map{ |output|
              Smash.new(
                :key => output[:output_key],
                :value => output[:output_value],
                :description => output[:description]
              )
            }
          ).valid_state
        end

        # Delete the stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [TrueClass, FalseClass]
        def stack_destroy(stack)
          raise NotImplementedError
        end

        # Fetch stack template
        #
        # @param stack [Stack]
        # @return [Smash] stack template
        def stack_template_load(stack)
          if(stack.persisted?)
            result = request(
              :method => :get,
              :path => "/stacks/#{stack.name}/#{stack.id}/template"
            )
            result.fetch(:body, Smash.new)
          else
            Smash.new
          end
        end

        # Return all stacks
        #
        # @param options [Hash] filter
        # @return [Array<Models::Orchestration::Stack>]
        # @todo check if we need any mappings on state set
        def stack_all(options={})
          result = request(
            :method => :get,
            :path => '/stacks'
          )
          result.fetch(:body, :stacks, []).map do |s|
            Stack.new(
              self,
              :id => s[:id],
              :creation_time => Time.parse(s[:creation_time]),
              :description => s[:description],
              :name => s[:stack_name],
              :state => s[:stack_status].downcase.to_sym,
              :status => s[:stack_status],
              :status_reason => s[:stack_status_reason],
              :updated_time => s[:updated_time].to_s.empty? ? nil : Time.parse(s[:updated_time])
            ).valid_state
          end
        end

        # Return all resources for stack
        #
        # @param stack [Models::Orchestration::Stack]
        # @return [Array<Models::Orchestration::Stack::Resource>]
        def resource_all(stack)
          result = request(
            :method => :get,
            :path => "/stacks/#{stack.name}/#{stack.id}/resources",
            :expects => 200
          )
          result.fetch(:body, :resources, []).map do |resource|
            Stack::Resource.new(
              stack,
              :id => resource[:physical_resource_id],
              :name => resource[:resource_name],
              :type => resource[:resource_type],
              :logical_id => resource[:logical_resource_id],
              :state => resource[:resource_status].downcase.to_sym,
              :status => resource[:resource_status],
              :status_reason => resource[:resource_status_reason],
              :updated_time => Time.parse(resource[:updated_time])
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
        def event_all(stack)
          result = request(
            :path => "/stacks/#{stack.name}/#{stack.id}/events",
            :method => :get,
            :expects => 200
          )
          result.fetch(:body, :events, []).map do |event|
            Stack::Event.new(
              stack,
              :id => event[:id],
              :resource_id => event[:physical_resource_id],
              :resource_name => event[:resource_name],
              :resource_logical_id => event[:logical_resource_id],
              :resource_state => event[:resource_status].downcase.to_sym,
              :resource_status => event[:resource_status],
              :resource_status_reason => event[:resource_status_reason],
              :time => Time.parse(event[:event_time])
            ).valid_state
          end
        end

        # Return all new events for event collection
        #
        # @param events [Models::Orchestration::Stack::Events]
        # @return [Array<Models::Orchestration::Stack::Event>]
        def event_all_new(events)
          raise NotImplementedError
        end

        # Reload the stack event data from the API
        #
        # @param resource [Models::Orchestration::Stack::Event]
        # @return [Models::Orchestration::Event]
        def event_reload(event)
          raise NotImplementedError
        end

      end
    end
  end
end
