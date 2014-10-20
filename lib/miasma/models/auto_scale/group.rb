require 'miasma'

module Miasma
  module Models
    class AutoScale
      # Abstract group
      class Group < Types::Model

        class Server < Types::ThinModel

          model Miasma::Models::Compute::Server
          attribute :name, String

          # @return [Miasma::Models::Compute::Server]
          def expand
            api.api_for(:compute).servers.get(self.id || self.name)
          end
        end

        attribute :name, String, :required => true
        attribute :minimum_size, Integer, :coerce => lambda{|v| v.to_i}
        attribute :maximum_size, Integer, :coerce => lambda{|v| v.to_i}
        attribute :desired_size, Integer, :coerce => lambda{|v| v.to_i}
        attribute :current_size, Integer, :coerce => lambda{|v| v.to_i}
        attribute :state, Symbol, :allowed_values => []
        attribute :servers, Array

        on_missing :reload

        protected

        # Proxy save action up to the API
        def perform_save
          api.group_save(self)
        end

        # Proxy reload action up to the API
        def perform_reload
          api.group_reload(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.group_destroy(self)
        end

      end
    end
  end
end
