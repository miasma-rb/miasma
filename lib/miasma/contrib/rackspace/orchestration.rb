require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Rackspace < OpenStack

        include Contrib::RackspaceApiCore::ApiCommon

        # @return [Smash] external to internal resource mapping
        RESOURCE_MAPPING = Smash.new(
          'Rackspace::Cloud::Server' => Smash.new(
            :api => :compute,
            :collection => :servers
          ),
          'Rackspace::AutoScale::Group' => Smash.new(
            :api => :auto_scale,
            :collection => :groups
          )
        )

      end
    end
  end
end
