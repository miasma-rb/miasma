require 'miasma'

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
        # @return [Object]
        def load_data(args={})
          args = args.to_smash
          @data = Smash.new
          self.class.attributes.each do |name, options|
            val = args[name]
            if(options[:required] && !args.has_key?(name) && !options.has_key?(:default))
              raise ArgumentError.new("Missing required option: `#{name}`")
            end
            if(val.nil? && options[:default] && !args.has_key?(name))
              val = options[:default].respond_to?(:call) ? options[:default].call : options[:default]
            end
            if(args.has_key?(name) || val)
              self.send("#{name}=", val)
            end
          end
        end

        # Identifies valid state and automatically
        # merges dirty attributes into data, clears
        # dirty attributes
        #
        # @return [self]
        def valid_state
          data.merge!(dirty)
          dirty.clear
          self
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
          define_method(name) do
            dirty[name] || data[name]
          end
          define_method("#{name}=") do |val|
            to_check = multiple_values ? val : [val]
            to_check.each do |item|
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
            end
            dirty[name] = coerce ? coerce.call(val) : val
          end
          define_method("#{name}?") do
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
