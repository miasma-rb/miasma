require 'miasma'

module Miasma
  module Models
    class Storage
      # Abstract bucket
      class Bucket < Types::Model

        attribute :metadata, Hash, :coerce => lambda{|o| o.to_smash}

      end

    end
  end
end
