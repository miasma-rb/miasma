require 'miasma'

module Miasma
  module Models
    class Storage

      # Abstract file collection
      class Files < Types::Collection

        # Return files matching given filter
        #
        # @param options [Hash] filter options
        # @return [Array<File>]
        # @option options [String] :prefix key prefix
        def filter(options={})
          raise NotImplementedError
        end

      end

    end
  end
end
