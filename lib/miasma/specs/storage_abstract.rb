require 'open-uri'

MIASMA_STORAGE_ABSTRACT = ->{

  # Required `let`s:
  # * storage: storage API

  describe Miasma::Models::Storage, :vcr do

    it 'should provide #buckets collection' do
      storage.buckets.must_be_kind_of Miasma::Models::Storage::Buckets
    end

    describe Miasma::Models::Storage::Buckets do

      it 'should provide instance class used within collection' do
        storage.buckets.model.must_equal Miasma::Models::Storage::Bucket
      end

      it 'should build new instance for collection' do
        storage.buckets.build.must_be_kind_of Miasma::Models::Storage::Bucket
      end

      it 'should provide #all buckets' do
        storage.buckets.all.must_be_kind_of Array
      end

    end

    describe Miasma::Models::Storage::Bucket do

      it 'should act like a bucket' do
        bucket = storage.buckets.build(:name => 'miasma-test-bucket-010')
        bucket.save
        bucket.reload

        # should include the bucket
        storage.buckets.reload.get('miasma-test-bucket-010').wont_be_nil
        # should have a name
        bucket.name.must_equal 'miasma-test-bucket-010'
        # should have a #files collection
        bucket.files.must_be_kind_of Miasma::Models::Storage::Files
        #should provide #all files
        bucket.files.all.must_be_kind_of Array
        # should include reference to containing bucket
        bucket.files.bucket.must_equal bucket
        # should build new instance for collection
        bucket.files.build.must_be_kind_of Miasma::Models::Storage::File

        file_content = 'blahblahblah'
        file = bucket.files.build
        file.name = 'miasma-test-file'
        file.body = file_content
        file.save
        file.reload

        # should have a name
        file.name.must_equal 'miasma-test-file'
        # should have a size
        file.size.must_equal file_content.size
        # should have an updated timestamp
        file.updated.must_be_kind_of Time
        # should create a valid url
        open(file.url).read.must_equal file_content
        # should have a body
        file.body.must_respond_to :readpartial
        file.body.readpartial(Miasma::Models::Storage::READ_BODY_CHUNK_SIZE).must_equal file_content
        file.destroy

        big_file_content = '*' * Miasma::Models::Storage::MAX_BODY_SIZE_FOR_STRINGIFY
        big_file = bucket.files.build
        big_file.name = 'miasma-test-file-big'
        big_file.body = big_file_content
        big_file.save
        big_file.reload

        # should be the correct size
        big_file.size.must_equal big_file.size
        # should provide streaming body
        big_file.body.must_respond_to :readpartial
        content = big_file.body.readpartial(big_file.size)
        content.must_equal big_file_content
        big_file.destroy

        require 'tempfile'
        local_io_file = Tempfile.new('miasma-storage-test')
        big_io_content = '*' * (Miasma::Models::Storage::MAX_BODY_SIZE_FOR_STRINGIFY * 1.3)
        local_io_file.write big_io_content
        local_io_file.flush
        local_io_file.rewind
        remote_file = bucket.files.build
        remote_file.name = 'miasma-test-io-object-010'
        remote_file.body = local_io_file
        remote_file.save
        remote_file.reload

        # should be the correct size
        remote_file.size.must_equal local_io_file.size
        # should provide streaming body
        remote_file.body.must_respond_to :readpartial
        content = ''
        while(chunk = remote_file.body.readpartial(1024))
          content << chunk
        end
        content.must_equal big_io_content
        remote_file.destroy
        bucket.destroy
      end

    end

  end
}
