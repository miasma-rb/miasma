require "miasma"

module Miasma
  module Models
    class Queuing
      # Abstract balancer
      class Queue < Types::Model
        class Message < Types::Data
          attribute :origin, Queue, :required => true
          attribute :content, String, :required => true
          attribute :created, Time, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
          attribute :updated, Time, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
          attribute :timeout, Integer
        end

        class Receipt < Types::Data
          attribute :message, String, :required => true
          attribute :checksum, String
        end

        attribute :name, String, :required => true
        attribute :created, Time, :required => true, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
        attribute :updated, Time, :coerce => lambda { |v| Time.parse(v.to_s).localtime }
        attribute :maximum_message_size, Integer
        attribute :messages_available, Integer

        on_missing :reload

        # Deliver message(s) to the queue
        #
        # @param msg_or_msgs [String, Array<String>]
        # @param options [Hash]
        # @return [Array<Receipt>]
        def deliver(msg_or_msgs, options = {})
          result = perform_delivery(msg_or_msgs, options)
          result.is_a?(Array) ? result : [result]
        end

        # Receive message(s) from the queue
        #
        # @param options [Hash]
        # @return [Array<Message>]
        def receive(options = {})
          result = perform_receive(options)
          result.is_a?(Array) ? result : [result]
        end

        protected

        # Proxy delivery action up to the API
        def perform_delivery(msg, options = {})
          api.queue_deliver(self, msg, options)
        end

        # Proxy receive action up to the API
        def perform_receive(options = {})
          api.queue_receive(self, options)
        end

        # Proxy save action up to the API
        def perform_save
          api.queue_save(self)
        end

        # Proxy reload action up to the API
        def perform_reload
          api.queue_reload(self)
        end

        # Proxy destroy action up to the API
        def perform_destroy
          api.queue_destroy(self)
        end
      end
    end
  end
end
