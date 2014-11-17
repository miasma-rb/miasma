require 'miasma'

module Miasma
  module Models
    class Compute
      class Rackspace < OpenStack

        include Contrib::RackspaceApiCore::ApiCommon

      end
    end
  end
end
