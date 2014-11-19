require 'stringio'
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
              :id => ::File.join(bucket.name, file['Key']),
              :name => file['Key'],
              :updated => file['LastModified'],
              :size => file['Size'].to_i
            ).valid_state
          end
        end

        # Save file
        #
        # @param file [Models::Storage::File]
        # @return [Models::Storage::File]
        def file_save(file)
          if(file.dirty?)
            file.load_data(file.attributes)
            args = Smash.new
            args[:headers] = Smash[
              Smash.new(
                :content_type => 'Content-Type',
                :content_disposition => 'Content-Disposition',
                :content_encoding => 'Content-Encoding'
              ).map do |attr, key|
                if(file.attributes[attr])
                  [key, file.attributes[attr]]
                end
              end.compact
            ]
            if(file.attributes[:body].is_a?(IO) && file.body.length >= 102400)
              upload_id = request(
                args.merge(
                  Smash.new(
                    :path => uri_escape(file.name),
                    :endpoint => bucket_endpoint(bucket),
                    :params => {
                      :uploads => true
                    }
                  )
                )
              ).get(:body, 'InitiateMultipartUploadResult', 'UploadId')
              count = 1
              parts = []
              file.body.rewind
              while(content = file.body.read(102400))
                parts << [
                  count,
                  request(
                    :method => :put,
                    :path => uri_escape(file.name),
                    :endpoint => bucket_endpoint(bucket),
                    :headers => Smash.new(
                      'Content-Length' => content.size,
                      'Content-MD5' => Digest::MD5.hexdigest(content)
                    ),
                    :params => Smash.new(
                      'partNumber' => count,
                      'uploadId' => upload_id
                    ),
                    :body => content
                  ).get(:body, :headers, :etag)
                ]
                count += 1
              end
              complete = SimpleXml.xml_out(
                Smash.new(
                  'CompleteMultipartUpload' => {
                    'Part' => parts.map{|part|
                      {'PartNumber' => part.first, 'ETag' => part.last}
                    }
                  }
                ),
                'AttrPrefix' => true,
                'KeepRoot' => true
              )
              result = request(
                :method => :post,
                :path => uri_escape(file.name),
                :endpoint => bucket_endpoint(file.bucket),
                :params => Smash.new(
                  'UploadId' => upload_id
                ),
                :headers => Smash.new(
                  'Content-Length' => complete.size
                ),
                :body => complete
              )
              file.etag = result.get(:body, 'CompleteMultipartUploadResult', 'ETag')
            else
              if(file.attributes[:body].is_a?(IO) || file.attributes[:body].is_a?(StringIO))
                args[:headers]['Content-Length'] = file.body.length.to_s
                file.body.rewind
                args[:body] = file.body.read
                file.body.rewind
              end
              p args
              result = request(
                args.merge(
                  Smash.new(
                    :method => :put,
                    :path => uri_escape(file.name),
                    :endpoint => bucket_endpoint(file.bucket)
                  )
                )
              )
              file.etag = result.get(:headers, :etag)
            end
            file.id = ::File.join(file.bucket.name, file.name)
            file.valid_state
          end
          file
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
          if(file.persisted?)
            name = file.name
            result = request(
              :path => uri_escape(file.name),
              :endpoint => bucket_endpoint(file.bucket)
            )
            file.data.clear && file.dirty.clear
            info = result[:headers]
            file.load_data(
              :id => ::File.join(file.bucket.name, name),
              :name => name,
              :updated => info[:last_modified],
              :etag => info[:etag],
              :size => info[:content_length].to_i,
              :content_type => info[:content_type]
            ).valid_state
          end
          file
        end

        # Fetch the contents of the file
        #
        # @param file [Models::Storage::File]
        # @return [IO, HTTP::Response::Body]
        def file_body(file)
          if(file.persisted?)
            result = request(
              :path => uri_escape(file.name),
              :endpoint => bucket_endpoint(file.bucket)
            )
            content = result[:body]
            content.is_a?(String) ? StringIO.new(content) : content
          else
            StringIO.new('')
          end
        end

        # Simple callback to allow request option adjustments prior to
        # signature calculation
        #
        # @param opts [Smash] request options
        # @return [TrueClass]
        # @note this only updates when :body is defined. if a :post is
        # happening (which implicitly forces :form) or :json is used
        # it will not properly checksum. (but that's probably okay)
        def update_request(con, opts)
          con.default_headers['x-amz-content-sha256'] = Digest::SHA256.
            hexdigest(opts.fetch(:body, ''))
          true
        end

      end
    end
  end
end
