require 'miasma'

module Miasma
  module Models
    class Storage
      class Aws < Storage

        # Service name of the API
        API_SERVICE = 's3'
        # Supported version of the AutoScaling API
        API_VERSION = '2006-03-01'

        include Contrib::AwsApiCore::ApiCommon
        include Contrib::AwsApiCore::RequestUtils

        # Simple init override to force HOST and adjust region for
        # signatures if required
        def initialize(args)
          args = args.to_smash
          cache_region = args[:aws_region]
          args[:aws_region] = args.fetch(:aws_bucket_region, 'us-east-1')
          super(args)
          aws_region = cache_region
          if(aws_bucket_region)
            self.aws_host = "s3-#{aws_bucket_region}.amazonaws.com"
          else
            self.aws_host = 's3.amazonaws.com'
          end
        end

        # Save bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [Models::Storage::Bucket]
        def bucket_save(bucket)
          raise NotImplementedError
        end

        # Destroy bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [TrueClass, FalseClass]
        def bucket_destroy(bucket)
          raise NotImplementedError
        end

        # Reload the bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [Models::Storage::Bucket]
        def bucket_reload(bucket)
          raise NotImplementedError
        end

        # Custom bucket endpoint
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [String]
        # @todo properly escape bucket name
        def bucket_endpoint(bucket)
          ::File.join(endpoint, bucket.name)
        end

        # Return all buckets
        #
        # @return [Array<Models::Storage::Bucket>]
        def bucket_all
          result = request(:path => '/')
          [result.get(:body, 'ListAllMyBucketsResult', 'Buckets', 'Bucket')].flatten.compact.map do |bkt|
            Bucket.new(
              self,
              :id => bkt['Name'],
              :name => bkt['Name'],
              :created => bkt['CreationDate']
            ).valid_state
          end
        end

        # Return all files within bucket
        #
        # @param bucket [Bucket]
        # @return [Array<File>]
        def file_all(bucket)
          result = request(
            :path => '/',
            :endpoint => bucket_endpoint(bucket)
          )
          [result.get(:body, 'ListBucketResult', 'Contents')].flatten.compact.map do |file|
            File.new(
              bucket,
              :name => file['Key'],
              :updated => file['LastModified'],
              :size => file['Size'].to_i,
              :etag => file['Etag']
            ).valid_state
          end
        end

        # Save file
        #
        # @param file [Models::Storage::File]
        # @return [Models::Storage::File]
        def file_save(file)
          raise NotImplementedError
        end

        # Destroy file
        #
        # @param file [Models::Storage::File]
        # @return [TrueClass, FalseClass]
        def file_destroy(file)
          raise NotImplementedError
        end

        # Reload the file
        #
        # @param file [Models::Storage::File]
        # @return [Models::Storage::File]
        def file_reload(file)
          raise NotImplementedError
        end

        # Simple callback to allow request option adjustments prior to
        # signature calculation
        #
        # @param opts [Smash] request options
        # @return [TrueClass]
        def update_request(con, opts)
          con.default_headers['x-amz-content-sha256'] = Digest::SHA256.hexdigest('')
          true
        end

      end
    end
  end
end
