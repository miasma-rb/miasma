require 'miasma'
require 'securerandom'

module Miasma
  module Models
    class Storage
      class OpenStack < Storage

        include Contrib::OpenStackApiCore::ApiCommon

        # Save bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [Models::Storage::Bucket]
        def bucket_save(bucket)
          unless(bucket.persisted?)
            request(
              :path => full_path(bucket),
              :method => :put,
              :expects => [201, 204]
            )
            bucket.id = bucket.name
            bucket.valid_state
          end
          bucket
        end

        # Destroy bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [TrueClass, FalseClass]
        def bucket_destroy(bucket)
          if(bucket.persisted?)
            request(
              :path => full_path(bucket),
              :method => :delete,
              :expects => 204
            )
            true
          else
            false
          end
        end

        # Reload the bucket
        #
        # @param bucket [Models::Storage::Bucket]
        # @return [Models::Storage::Bucket]
        def bucket_reload(bucket)
          if(bucket.persisted?)
            begin
              result = request(
                :path => full_path(bucket),
                :method => :head,
                :expects => 204,
                :params => {
                  :format => 'json'
                }
              )
              meta = Smash.new.tap do |m|
                result[:response].headers.each do |k,v|
                  if(k.to_s.start_with?('X-Container-Meta-'))
                    m[k.sub('X-Container-Meta-', '')] = v
                  end
                end
              end
              bucket.metadata = meta unless meta.empty?
              bucket.valid_state
            rescue Error::ApiError::RequestError => e
              if(e.response.status == 404)
                bucket.data.clear
                bucket.dirty.clear
              else
                raise
              end
            end
          end
          bucket
        end

        # Return all buckets
        #
        # @return [Array<Models::Storage::Bucket>]
        def bucket_all
          result = request(
            :path => '/',
            :expects => [200, 204],
            :params => {
              :format => 'json'
            }
          )
          [result[:body]].flatten.compact.map do |bkt|
            Bucket.new(
              self,
              :id => bkt['name'],
              :name => bkt['name']
            ).valid_state
          end
        end

        # Return filtered files
        #
        # @param args [Hash] filter options
        # @return [Array<Models::Storage::File>]
        def file_filter(bucket, args)
          result = request(
            :path => full_path(bucket),
            :expects => [200, 204],
            :params => {
              :prefix => args[:prefix],
              :format => :json
            }
          )
          [result[:body]].flatten.compact.map do |file|
            File.new(
              bucket,
              :id => ::File.join(bucket.name, file[:name]),
              :name => file[:name],
              :updated => file[:last_modified],
              :size => file[:bytes].to_i
            ).valid_state
          end
        end

        # Return all files within bucket
        #
        # @param bucket [Bucket]
        # @return [Array<File>]
        # @todo pagination auto-follow
        def file_all(bucket)
          result = request(
            :path => full_path(bucket),
            :expects => [200, 204],
            :params => {
              :format => :json
            }
          )
          [result[:body]].flatten.compact.map do |file|
            File.new(
              bucket,
              :id => ::File.join(bucket.name, file[:name]),
              :name => file[:name],
              :updated => file[:last_modified],
              :size => file[:bytes].to_i
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
            if(file.attributes[:body].is_a?(IO) && file.body.size >= Storage::MAX_BODY_SIZE_FOR_STRINGIFY)
              parts = []
              file.body.rewind
              while(content = file.body.read(Storage::READ_BODY_CHUNK_SIZE))
                data = Smash.new(
                  :path => "segments/#{full_path(file)}-#{SecureRandom.uuid}",
                  :etag => Digest::MD5.hexdigest(content),
                  :size_bytes => content.length
                )
                request(
                  :path => data[:path],
                  :method => :put,
                  :expects => 201,
                  :headers => {
                    'Content-Length' => data[:size_bytes],
                    'Etag' => data[:etag]
                  }
                )
                parts << data
              end
              result = request(
                :path => full_path(file),
                :method => :put,
                :expects => 201,
                :params => {
                  'multipart-manifest' => :put
                },
                :json => parts
              )
            else
              if(file.attributes[:body].is_a?(IO) || file.attributes[:body].is_a?(StringIO))
                args[:headers]['Content-Length'] = file.body.size.to_s
                file.body.rewind
                args[:body] = file.body.read
                file.body.rewind
              end
              result = request(
                args.merge(
                  :method => :put,
                  :expects => 201,
                  :path => full_path(file)
                )
              )
            end
            file.id = ::File.join(file.bucket.name, file.name)
            file.reload
          end
          file
        end

        # Destroy file
        #
        # @param file [Models::Storage::File]
        # @return [TrueClass, FalseClass]
        def file_destroy(file)
          if(file.persisted?)
            request(
              :path => full_path(file),
              :method => :delete
            )
            true
          else
            false
          end
        end

        # Reload the file
        #
        # @param file [Models::Storage::File]
        # @return [Models::Storage::File]
        def file_reload(file)
          if(file.persisted?)
            result = request(
              :path => full_path(file),
              :method => :head
            )
            info = result[:headers]
            new_info = Smash.new.tap do |data|
              data[:updated] = info[:last_modified]
              data[:etag] = info[:etag]
              data[:size] = info[:content_length].to_i
              data[:content_type] = info[:content_type]
              meta = Smash.new.tap do |m|
                result[:response].headers.each do |k, v|
                  if(k.to_s.start_with?('X-Object-Meta-'))
                    m[k.sub('X-Object-Meta-', '')] = v
                  end
                end
              end
              data[:metadata] = meta unless meta.empty?
            end
            file.load_data(file.attributes.deep_merge(new_info))
            file.valid_state
          end
          file
        end

        # Create publicly accessible URL
        #
        # @param timeout_secs [Integer] seconds available
        # @return [String] URL
        # @todo where is this in swift?
        def file_url(file, timeout_secs)
          if(file.persisted?)
            raise NotImplementedError
          else
            raise Error::ModelPersistError.new "#{file} has not been saved!"
          end
        end

        # Fetch the contents of the file
        #
        # @param file [Models::Storage::File]
        # @return [IO, HTTP::Response::Body]
        def file_body(file)
          if(file.persisted?)
            result = request(:path => full_path(file))
            content = result[:body]
            begin
              if(content.is_a?(String))
                StringIO.new(content)
              else
                if(content.respond_to?(:stream!))
                  content.stream!
                end
                content
              end
            rescue HTTP::StateError
              StringIO.new(content.to_s)
            end
          else
            StringIO.new('')
          end
        end

        # @return [String] escaped bucket name
        def bucket_path(bucket)
          uri_escape(bucket.name)
        end

        # @return [String] escaped file path
        def file_path(file)
          file.name.split('/').map do |part|
            uri_escape(part)
          end.join('/')
        end

        # Provide full path for object
        #
        # @param file_or_bucket [File, Bucket]
        # @return [String]
        def full_path(file_or_bucket)
          path = ''
          if(file_or_bucket.respond_to?(:bucket))
            path << '/' << bucket_path(file_or_bucket.bucket)
          end
          path << '/' << file_path(file_or_bucket)
          path
        end

        # URL string escape
        #
        # @param string [String] string to escape
        # @return [String] escaped string
        # @todo move this to common module
        def uri_escape(string)
          string.to_s.gsub(/([^a-zA-Z0-9_.\-~])/) do
            '%' << $1.unpack('H2' * $1.bytesize).join('%').upcase
          end
        end

      end
    end
  end
end
