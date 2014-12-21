require 'miasma'

module Miasma
  module Models
    class AutoScale
      class Aws < AutoScale

        # Service name of the API
        API_SERVICE = 'autoscaling'
        # Supported version of the AutoScaling API
        API_VERSION = '2011-01-01'

        include Contrib::AwsApiCore::ApiCommon
        include Contrib::AwsApiCore::RequestUtils

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
          if(group.id || group.name)
            load_group_data(group)
          end
          group
        end

        # Delete auto scale group
        #
        # @param group [Models::AutoScale::Group]
        # @return [TrueClass, FalseClass]
        def group_destroy(group)
          raise NotImplemented
        end

        # Fetch groups or update provided group data
        #
        # @param group [Models::AutoScale::Group]
        # @return [Array<Models::AutoScale::Group>]
        def load_group_data(group=nil)
          params = Smash.new('Action' => 'DescribeAutoScalingGroups')
          if(group)
            params.merge('AutoScalingGroupNames.member.1' => group.id || group.name)
          end
          result = all_result_pages(nil, :body, 'DescribeAutoScalingGroupsResponse', 'DescribeAutoScalingGroupsResult', 'AutoScalingGroups', 'member') do |options|
            request(
              :path => '/',
              :params => options.merge(params)
            )
          end.map do |grp|
            (group || Group.new(self)).load_data(
              :id => grp['AutoScalingGroupName'],
              :name => grp['AutoScalingGroupName'],
              :servers => [grp.get('Instances', 'member')].flatten(1).compact.map{|i|
                Group::Server.new(self, :id => i['InstanceId'])
              },
              :minimum_size => grp['MinSize'],
              :maximum_size => grp['MaxSize'],
              :status => grp['Status'],
              :load_balancers => [grp.get('LoadBalancerNames', 'member')].flatten(1).compact.map{|i|
                Group::Balancer.new(self, :id => i, :name => i)
              }
            ).valid_state
          end
        end


        # Return all auto scale groups
        #
        # @param options [Hash] filter
        # @return [Array<Models::AutoScale::Group>]
        def group_all(options={})
          load_group_data
        end

      end
    end
  end
end
