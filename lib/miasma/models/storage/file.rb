require 'miasma'

module Miasma
  module Models
    class Storage

      # Abstract file
      class File < Types::Collection

        attribute :body, [String, IO], :default => ''
        attribute :content_type, String
        attribute :content_disposition, String
        attribute :etag, String
        attribute :last_modified, DateTime
        attribute :metadata, Hash, :coerce => lambda{|o| o.to_smash}

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
