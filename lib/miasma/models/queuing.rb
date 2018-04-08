require "miasma"

module Miasma
  module Models
    # Abstract queue API
    class Queuing < Types::API
      autoload :Queue, "miasma/models/queuing/queue"
      autoload :Queues, "miasma/models/queuing/queues"

      # Queues
      #
      # @param filter [Hash] filtering options
      # @return [Types::Collections<Models::Queuing::Queue>] queues
      def queues(filter = {})
        memoize(:queues) do
          Queues.new(self)
        end
      end

      # Save the queue
      #
      # @param queue [Models::Queuing::Queue]
      # @return [Models::Queuing::Queue]
      def queue_save(queue)
        raise NotImplementedError
      end

      # Reload the queue data from the API
      #
      # @param queue [Models::Queuing::Queue]
      # @return [Models::Queuing::Queue]
      def queue_reload(queue)
        raise NotImplementedError
      end

      # Delete the queue
      #
      # @param queue [Models::Queuing::Queue]
      # @return [TrueClass, FalseClass]
      def queue_destroy(queue)
        raise NotImplementedError
      end

      # Return all queues
      #
      # @param options [Hash] filter
      # @return [Array<Models::Queuing::Queue>]
      def queue_all(options = {})
        raise NotImplementedError
      end

      # Deliver message(s) to queue
      #
      # @param queue [Models::Queuing::Queue]
      # @param msg_or_msgs [String, Array<String>] message(s) to deliver
      # @param options [Hash] delivery options
      # @return [Receipt]
      def queue_deliver(queue, msg_or_msgs, options = {})
        raise NotImplementedError
      end

      # Receive message(s) from queue
      #
      # @param queue [Models::Queuing::Queue]
      # @param options [Hash] delivery options
      # @return [Queue::Message, Array<Queue::Message>]
      def queue_receive(queue, options = {})
        raise NotImplementedError
      end
    end
  end
end
