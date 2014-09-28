require 'miasma'

module Miasma

  module Utils
    # Animal stylings on strings
    module AnimalStrings

      # Camel case string
      # @param string [String]
      # @return [String]
      def camel(string)
        string.to_s.split('_').map{|k| "#{k.slice(0,1).upcase}#{k.slice(1,k.length)}"}.join
      end

      # Snake case (underscore) string
      #
      # @param string [String]
      # @return [String]
      def snake(string)
        string.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').gsub('-', '_').downcase
      end

    end

    extend AnimalStrings
  end

end
