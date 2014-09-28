require 'miasma'

module Miasma
  module Utils
    # Memoization helpers
    module Memoization

      # Memoize data
      #
      # @param key [String, Symbol] identifier for data
      # @param direct [Truthy, Falsey] direct skips key prepend of object id
      # @yield block to create data
      # @yieldreturn data to memoize
      # @return [Object] data
      def memoize(key, direct=false)
        unless(direct)
          key = "#{self.object_id}_#{key}"
        end
        unless(Thread.current[key])
          Thread.current[key] = yield
        end
        Thread.current[key]
      end

      # Remove memoized value
      #
      # @param key [String, Symbol] identifier for data
      # @param direct [Truthy, Falsey] direct skips key prepend of object id
      # @return [NilClass]
      def unmemoize(key, direct=false)
        unless(direct)
          key = "#{self.object_id}_#{key}"
        end
        Thread.current[key] = nil
      end

    end
  end
end
