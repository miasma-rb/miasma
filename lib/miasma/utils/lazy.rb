require 'miasma'
require 'digest/sha2'

module Miasma
  module Utils
    # Adds functionality to facilitate laziness
    module Lazy

      # Instance methods for laziness
      module InstanceMethods

        # @return [Smash] argument hash
        def data
          unless(@data)
            @data = Smash.new
          end
          @data
        end

        # @return [Smash] updated data
        def dirty
          unless(@dirty)
            @dirty = Smash.new
          end
          @dirty
        end

        # @return [Smash] current data state
        def attributes
          data.merge(dirty)
        end

        # Create new instance
        #
        # @param args [Hash]
        # @return [self]
        def load_data(args={})
          args = args.to_smash
          @data = Smash.new
          self.class.attributes.each do |name, options|
            val = args[name]
            if(options[:required] && !args.has_key?(name) && !options.has_key?(:default))
              raise ArgumentError.new("Missing required option: `#{name}`")
            end
            if(val.nil? && !args.has_key?(name) && options[:default])
              if(options[:default])
                val = options[:default].respond_to?(:call) ? options[:default].call : options[:default]
              end
            end
            if(args.has_key?(name) || val)
              self.send("#{name}=", val)
            end
          end
          self
        end

        # Identifies valid state and automatically
        # merges dirty attributes into data, clears
        # dirty attributes
        #
        # @return [self]
        def valid_state
          data.merge!(dirty)
          dirty.clear
          @_checksum = Digest::SHA256.hexdigest(MultiJson.dump(data))
          self
        end

        # Model is dirty or specific attribute is dirty
        #
        # @param attr [String, Symbol] name of attribute
        # @return [TrueClass, FalseClass] model or attribute is dirty
        def dirty?(attr=nil)
          if(attr)
            dirty.has_key?(attr)
          else
            if(@_checksum)
              !dirty.empty? ||
                @_checksum != Digest::SHA256.hexdigest(MultiJson.dump(data))
            else
              true
            end
          end
        end

        # @return [String]
        def to_s
          "<#{self.class.name}:#{object_id}>"
        end

        # @return [String]
        def inspect
          "<#{self.class.name}:#{object_id} [#{data.inspect}]>"
        end

      end

      # Class methods for laziness
      module ClassMethods

        # Add new attributes to class
        #
        # @param name [String]
        # @param type [Class, Array<Class>]
        # @param options [Hash]
        # @option options [TrueClass, FalseClass] :required must be provided on initialization
        # @option options [Object, Proc] :default default value
        # @option options [Proc] :coerce
        # @return [nil]
        def attribute(name, type, options={})
          name = name.to_sym
          options = options.to_smash
          attributes[name] = Smash.new(:type => type).merge(options)
          coerce = attributes[name][:coerce]
          valid_types = [attributes[name][:type], NilClass].flatten.compact
          allowed_values = attributes[name][:allowed]
          multiple_values = attributes[name][:multiple]
          depends_on = attributes[name][:depends]
          define_method(name) do
            send(depends_on) if depends_on
            self.class.on_missing(self) unless data.has_key?(name) || dirty.has_key?(name)
            dirty[name] || data[name]
          end
          define_method("#{name}=") do |val|
            values = multiple_values && val.is_a?(Array) ? val : [val]
            values.map! do |item|
              valid_type = valid_types.detect do |klass|
                item.is_a?(klass)
              end
              if(coerce && !valid_type)
                item = coerce.arity == 2 ? coerce.call(item, self) : coerce.call(item)
              end
              valid_type = valid_types.detect do |klass|
                item.is_a?(klass)
              end
              unless(valid_type)
                raise TypeError.new("Invalid type for `#{name}` (#{item} <#{item.class}>). Valid - #{valid_types.map(&:to_s).join(',')}")
              end
              if(allowed_values)
                unless(allowed_values.include?(item))
                  raise ArgumentError.new("Invalid value provided for `#{name}` (#{item.inspect}). Allowed - #{allowed_values.map(&:inspect).join(', ')}")
                end
              end
              item
            end
            if(!multiple_values && !val.is_a?(Array))
              dirty[name] = values.first
            else
              dirty[name] = values
            end
          end
          define_method("#{name}?") do
            send(depends_on) if depends_on
            self.class.on_missing(self) unless data.has_key?(name)
            !!data[name]
          end
          nil
        end

        # Return attributes
        #
        # @param args [Symbol] :required or :optional
        # @return [Array<Hash>]
        def attributes(*args)
          @attributes ||= Smash.new
          if(args.include?(:required))
            Smash[@attributes.find_all{|k,v| v[:required]}]
          elsif(args.include?(:optional))
            Smash[@attributes.find_all{|k,v| !v[:required]}]
          else
            @attributes
          end
        end

        # Instance method to call on missing attribute or
        # object to call method on if set
        #
        # @param param [Symbol, Object]
        # @return [Symbol]
        def on_missing(param=nil)
          if(param)
            if(param.is_a?(Symbol))
              @missing_method = param
            else
              if(@missing_method)
                param.send(@missing_method)
              end
              @missing_method
            end
          else
            @missing_method
          end
        end

        # Directly set attribute hash
        #
        # @param attrs [Hash]
        # @return [TrueClass]
        # @todo need deep dup here
        def set_attributes(attrs)
          @attributes = attrs.to_smash
          true
        end

      end

      class << self

        # Injects laziness into class
        #
        # @param klass [Class]
        def included(klass)
          klass.class_eval do
            include InstanceMethods
            extend ClassMethods

            class << self

              def inherited(klass)
                klass.set_attributes(self.attributes)
              end

            end
          end
        end

      end

    end
  end
end
