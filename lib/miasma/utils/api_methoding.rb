require 'miasma'

module Miasma
  module Utils

    module ApiMethoding

      # Generate the supported API method for
      # a given action
      def api_method_for(action)
        klass = self.respond_to?(:model) ? model : self.class
        m_name = "#{Bogo::Utility.snake(klass.split('::').last)}_#{action}"
        self.api.respond_to?(m_name) ? m_name : nil
      end

    end

  end
end
