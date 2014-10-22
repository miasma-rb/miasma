require 'miasma'

module Miasma
  module Models
    class LoadBalancer
      # Abstract balancer
      class Balancer < Types::Model

        class Server < Types::ThinModel
          model Miasma::Models::Compute::Server
        end

        class Address < Types::Data
          attribute :address, String, :required => true
          attribute :version, Integer, :default => 4
        end

        class HealthCheck < Types::Data
          attribute :interval, Integer
          attribute :target, String, :required => true
          attribute :healthy_threshold, Integer
          attribute :unhealthy_threshold, Integer
          attribute :timeout, Integer
        end

        class Listener < Types::Data
          attribute :protocol, String, :required => true
          attribute :load_balancer_port, Integer, :required => true
          attribute :instance_protocol, String, :required => true
          attribute :instance_port, Integer, :required => true
        end

        attribute :name, String
        attribute :state, Symbol, :allowed_values => [:active, :pending]
        attribute :status, String
        attribute :servers, Server, :multiple => true
        attribute :public_addresses, Address, :multiple => true, :default => []
        attribute :private_addresses, Address, :multiple => true, :default => []
        attribute :health_check, HealthCheck
        attribute :created, [String, Time], :coerce => lambda{|v| v.is_a?(Time) ? v : Time.parse(v)}
        attribute :updated, [String, Time], :coerce => lambda{|v| v.is_a?(Time) ? v : Time.parse(v)}

        on_missing :reload

        # @return [Array<Address>] all addresses
        def addresses
          public_addresses + private_addresses
        end

        protected

        # Proxy save action up to the API
        def perform_save
          api.balancer_save(self)
        end

        # Proxy reload action up to the API
        def perform_reload
          api.balancer_reload(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.balancer_destroy(self)
        end

      end
    end
  end
end
