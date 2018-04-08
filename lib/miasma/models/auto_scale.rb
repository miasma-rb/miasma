require "miasma"

module Miasma
  module Models
    # Abstract auto scale API
    class AutoScale < Types::Api
      autoload :Group, "miasma/models/auto_scale/group"
      autoload :Groups, "miasma/models/auto_scale/groups"

      # Auto scale groups
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collection<Models::AutoScale::Groups>] auto scale groups
      def groups(filter = {})
        memoize(:groups) do
          Groups.new(self)
        end
      end

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
        raise NotImplementedError
      end

      # Delete auto scale group
      #
      # @param group [Models::AutoScale::Group]
      # @return [TrueClass, FalseClass]
      def group_destroy(group)
        raise NotImplementedError
      end

      # Return all auto scale groups
      #
      # @param options [Hash] filter
      # @return [Array<Models::AutoScale::Group>]
      def group_all(options = {})
        raise NotImplementedError
      end
    end
  end
end
