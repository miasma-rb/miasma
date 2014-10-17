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
        unless(_memo.has_key?(key))
          _memo[key] = yield
        end
        _memo[key]
      end

      def _memo
        Thread.current[:miasma_memoization] ||= Smash.new
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
        _memo.delete(key)
      end

      # Remove all memoized values
      #
      # @return [TrueClass]
      def clear_memoizations!
        _memo.keys.find_all do |key|
          key.to_s.start_with?("#{self.object_id}_")
        end.each do |key|
          _memo.delete(key)
        end
        true
      end

    end
  end
end
