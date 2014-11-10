require 'hashie'
require 'digest/sha2'
require 'miasma'

module Miasma
  module Utils

    # Customized Hash
    class Smash < Hash
      include Hashie::Extensions::IndifferentAccess
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::DeepMerge
      include Hashie::Extensions::Coercion

      coerce_value Hash, Smash

      # Create new instance
      #
      # @param args [Object] argument list
      def initialize(*args)
        base = nil
        if(args.first.is_a?(::Hash))
          base = args.shift
        end
        super *args
        if(base)
          self.replace(base.to_smash)
        end
      end

      def merge!(hash)
        hash = hash.to_smash unless hash.is_a?(::Smash)
        super(hash)
      end

      # Get value at given path
      #
      # @param args [String, Symbol] key path to walk
      # @return [Object, NilClass]
      def retrieve(*args)
        args.inject(self) do |memo, key|
          if(memo.is_a?(Hash))
            memo.to_smash[key]
          else
            nil
          end
        end
      end
      alias_method :get, :retrieve

      # Fetch value at given path or return a default value
      #
      # @param args [String, Symbol, Object] key path to walk. last value default to return
      # @return [Object] value at key or default value
      def fetch(*args)
        default_value = args.pop
        retrieve(*args) || default_value
      end

      # Set value at given path
      #
      # @param args [String, Symbol, Object] key path to walk. set last value to given path
      # @return [Object] value set
      def set(*args)
        unless(args.size > 1)
          raise ArgumentError.new 'Set requires at least one key and a value'
        end
        value = args.pop
        set_key = args.pop
        leaf = args.inject(self) do |memo, key|
          unless(memo[key].is_a?(Hash))
            memo[key] = Smash.new
          end
          memo[key]
        end
        leaf[set_key] = value
        value
      end

      # Convert to Hash
      #
      # @return [Hash]
      def to_hash
        self.to_type_converter(::Hash, :to_hash)
      end

      # Calculate checksum of hash (sha256)
      #
      # @return [String] checksum
      def checksum
        Digest::SHA256.hexdigest(self.to_s)
      end

    end
  end

end

# Hook helper into toplevel `Hash`
class Hash

  # Convert to Smash
  #
  # @return [Smash]
  def to_smash
    self.to_type_converter(::Smash, :to_smash)
  end
  alias_method :hulk_smash, :to_smash

  protected

  # Convert to type
  #
  # @param type [Class] hash type
  # @param convert_call [Symbol] builtin hash convert
  # @return [Smash]
  def to_type_converter(type, convert_call)
    type.new.tap do |smash|
      self.sort_by do |entry|
        entry.first.to_s
      end.each do |k,v|
        smash[k.is_a?(Symbol) ? k.to_s : k] = smash_conversion(v, convert_call)
      end
    end
  end

  # Convert object to smash if applicable
  #
  # @param obj [Object]
  # @param convert_call [Symbol] builtin hash convert
  # @return [Smash, Object]
  def smash_conversion(obj, convert_call)
    case obj
    when Hash
      obj.send(convert_call)
    when Array
      obj.map do |i|
        smash_conversion(i, convert_call)
      end
    else
      obj
    end
  end

end

unless(defined?(Smash))
  Smash = Miasma::Utils::Smash
end
