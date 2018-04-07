require "miasma"

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

        class Balancer < Types::ThinModel
          model Miasma::Models::LoadBalancer::Balancer
          attribute :name, String

          # @return [Miasma::Models::LoadBalancer::Balancer]
          def expand
            api.api_for(:load_balancer).balancers.get(self.id || self.name)
          end
        end

        attribute :name, String, :required => true
        attribute :created, Time, :coerce => lambda { |v| Time.parse(v.to_s) }
        attribute :load_balancers, Balancer, :multiple => true, :coerce => lambda { |v, obj| Balancer.new(obj.api, v) }
        attribute :minimum_size, Integer, :coerce => lambda { |v| v.to_i }
        attribute :maximum_size, Integer, :coerce => lambda { |v| v.to_i }
        attribute :desired_size, Integer, :coerce => lambda { |v| v.to_i }
        attribute :current_size, Integer, :coerce => lambda { |v| v.to_i }
        attribute :state, Symbol, :allowed_values => []
        attribute :servers, Server, :multiple => true, :coerce => lambda { |v, obj| Server.new(obj.api_for(:compute), v) }

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
