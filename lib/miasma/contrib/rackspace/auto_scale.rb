require 'miasma'

module Miasma
  module Models
    class AutoScale
      class Rackspace < AutoScale

        include Contrib::OpenStackApiCore::ApiCommon
        include Contrib::RackspaceApiCore::ApiCommon

        # Save auto scale group
        #
        # @param group [Models::AutoScale::Group]
        # @return [Models::AutoScale::Group]
        def group_save(group)
          raise NotImplementedError
        end

        # Reload the group data from the API
        #
        # @param group [Models::AutoScale::Group]
        # @return [Models::AutoScale::Group]
        def group_reload(group)
          if(group.persisted?)
            result = request(
              :method => :get,
              :path => "/groups/#{group.id}",
              :expects => 200
            )
            grp = result.get(:body, :group)
            group.load_data(
              :name => grp.get('groupConfiguration', :name),
              :minimum_size => grp.get('groupConfiguration', 'minEntities'),
              :maximum_size => grp.get('groupConfiguration', 'maxEntities'),
              :desired_size => grp.get(:state, 'desiredCapacity'),
              :current_size => grp.get(:state, 'activeCapacity'),
              :servers => grp.get(:state, :active).map{|s| AutoScale::Group::Server.new(self, :id => s[:id])}
            ).valid_state
          else
            group
          end
        end

        # Delete auto scale group
        #
        # @param group [Models::AutoScale::Group]
        # @return [TrueClass, FalseClass]
        def group_destroy(group)
          if(group.persisted?)
            request(
              :path => "/groups/#{group.id}",
              :method => :delete,
              :expects => 204
            )
            true
          else
            false
          end
        end

        # Return all auto scale groups
        #
        # @param options [Hash] filter
        # @return [Array<Models::AutoScale::Group>]
        def group_all(options={})
          result = request(
            :method => :get,
            :path => '/groups',
            :expects => 200
          )
          result.fetch(:body, 'groups', []).map do |lb|
            Group.new(
              self,
              :id => lb[:id],
              :name => lb.get(:state, :name),
              :current_size => lb.get(:state, 'activeCapacity'),
              :desired_size => lb.get(:state, 'desiredCapacity')
            ).valid_state
          end
        end

      end
    end
  end
end
