MIASMA_STORAGE_ABSTRACT = ->{

  # Required `let`s:
  # * storage: storage API
  # * cassette_prefix: cassette file prefix [String]

  describe Miasma::Models::Storage do

    it 'should provide #buckets collection' do
      storage.buckets.must_be_kind_of Miasma::Models::Storage::Buckets
    end

    describe Miasma::Models::Storage::Buckets do

      it 'should provide instance class used within collection' do
        storage.buckets.model.must_equal Miasma::Models::Storage::Bucket
      end

      it 'should build new instance for collection' do
        storage.buckets.build.must_be_kind_of Miasma::MOdels::Storage::Bucket
      end

      it 'should provide #all buckets' do
        VCR.use_cassette("#{cassette_prefix}_buckets_all") do
          storage.buckets.all.must_be_kind_of Array
        end
      end

    end

    describe Miasma::Models::Storage::Bucket do

      before do
        @instance = storage.buckets.build(:name => 'miasma-test-bucket-010')
        VCR.use_cassette("#{cassette_prefix}_storage_bucket_before_create") do |obj|
          @instance.save
          @instance.reload
        end
      end

      after do
        VCR.use_cassette("#{cassette_prefix}_storage_bucket_after_create") do |obj|
          @instance.destroy
        end
      end

      let(:bucket){ @instance }

      describe 'test bucket' do

        describe 'buckets collection' do

          it 'should be included within the buckets collection' do
            VCR.use_cassette("#{cassette_prefix}_storage_bucket_collection") do
              storage.buckets.reload.get('miasma-test-bucket-010').wont_be_nil
            end
          end

        end

        describe 'instance methods' do

          it 'should have a name' do
            bucket.name.must_equal 'miasma-test-bucket-010'
          end

          it 'should have a #files collection' do
            bucket.files.must_be_kind_of Miasma::Models::Storage::Files
          end

          it 'should provide #all files' do
            VCR.use_cassette("#{cassette_prefix}_storage_bucket_files_collection") do
              bucket.files.all.must_be_kind_of Array
            end
          end

        end

        describe Miasma::Models::Storage::Files do

          it 'should include reference to containing bucket' do
            bucket.files.bucket.must_equal bucket
          end

          it 'should build new instance for collection' do
            bucket.files.build.must_be_kind_of Miasma::Models::Storage::File
          end

        end

        describe Miasma::Models::Storage::File do

          before do
            @file_content = 'blahblahblah'
            @file = bucket.files.file.build
            @file.name = 'miasma-test-file'
            @file.body = @file_content
            VCR.use_cassette("#{cassette_prefix}_storage_file_before_create") do
              @file.save
              @file.reload
            end
          end

          after do
            VCR.use_cassette("#{cassette_prefix}_storage_file_after_create") do
              @file.destroy
            end
          end

          let(:file){ @file }
          let(:file_content){ @file_content }

          describe 'instance methods' do

            it 'should have a name' do
              file.name.must_equal 'miasma-test-file'
            end

            it 'should have a size' do
              file.size.must_equal file_content.size
            end

            it 'should have an updated timestamp' do
              file.updated.must_be_kind_of Time
            end

            it 'should have a body' do
              VCR.use_cassette("#{cassette_prefix}_storage_file_body") do
                file.body.must_respond_to :readpartial
                file.body
                  .readpartial(Miasma::Models::Storage::READ_BODY_CHUNK_SIZE).
                  must_equal file_content
              end
            end

          end

        end

        describe 'Large file object' do

          before do
            @big_file_content = '*' * (Miasma::Models::Storage::MAX_BODY_SIZE_FOR_STRINGIFY * 2)
            @big_file = bucket.files.file.build
            @big_file.name = 'miasma-test-file-big'
            @big_file.body = @big_file_content
            VCR.use_cassette("#{cassette_prefix}_storage_file_before_create_big") do
              @big_file.save
              @big_file.reload
            end
          end

          after do
            VCR.use_cassette("#{cassette_prefix}_storage_file_after_create_big") do
              @big_file.destroy
            end
          end

          let(:big_file){ @big_file }
          let(:big_file_content){ @big_file_content }

          describe 'body access' do

            it 'should be the correct size' do
              big_file.size.must_equal @big_file.size
            end

            it 'should provide streaming body' do
              VCR.use_cassette("#{cassette_prefix}_storage_file_big_body") do
                big_file.body.must_respond_to :readpartial
                content = ''
                while(chunk = big_file.body.readpartial(1024))
                  content << chunk
                end
                content.must_equal big_file_content
              end
            end

          end

        end

      end


    end

  end
}
