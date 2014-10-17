require 'miasma'

module Miasma
  module Models
    class Orchestration
      class Rackspace < Compute

        include Contrib::RackspaceApiCore::ModelCommon

        def stack_save(stack)
        end

        def stack_destroy(stack)
        end

        def stack_reload(stack)
        end

        def stack_all
          result = request(
            :method => :git,
            :path => '/stacks'
          )
          result
        end

      end
    end
  end
end
