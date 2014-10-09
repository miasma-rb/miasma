require 'miasma'

module Miasma
  module Models
    class Compute
      # Abstract server
      class Server < Types::Model

        # Data container for networks
        class Network

          include Utils::Lazy

          attribute :name, String
          attribute :id, [String, Integer], :required => true

          def initialize(args={})
            load_data(args)
          end

        end

        # Data container for IP addresses
        class Address

          include Utils::Lazy

          attribute :version, Integer, :required => true, :default => 4
          attribute :address, String, :required => true
          attribute :label, String
          attribute :id, [String, Integer]

          # Create new instance
          #
          # @param args [Hash]
          # @option args [Integer] :version IP verion
          # @option args [String] :address IP address
          # @option args [String] :label optional label describing address
          # @option args [String, Integer] :id optional ID for network
          # @return [self]
          def initialize(args={})
            load_data(args)
            valid_state
          end

        end

        attribute :name, String, :required => true
        attribute :image_id, [String, Numeric], :required => true
        attribute :flavor_id, [String, Numeric], :required => true
        attribute :state, Symbol, :allowed => [:running, :stopped, :pending, :terminated]
        attribute :status, String
        attribute :addresses_public, Address, :default => [], :multiple => true
        attribute :addresses_private, Address, :default => [], :multiple => true
        attribute :networks, Network, :default => [], :multiple => true
        attribute :personality, [Hash, String], :default => {}
        attribute :metadata, Hash, :coerce => lambda{|o| o.to_smash}
        attribute :key_name, String

        # @return [Array<Smash>]
        def addresses
          addresses_public + addresses_private
        end

        # @return [String] public IP address
        def address
          obj = addresses_public.detect do |addr|
            addr.version == 4
          end
          obj.address if obj
        end

        protected

        # Proxy save action up to the API
        def perform_save
          api.server_save(self)
        end

        # Proxy reload action up to the API
        def perform_reload
          api.server_reload(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.server_destroy(self)
        end
      end

    end
  end
end
