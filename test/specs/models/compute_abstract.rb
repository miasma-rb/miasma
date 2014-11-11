MIASMA_COMPUTE_ABSTRACT = ->{

  describe Miasma::Models::Compute do

    it 'should provide #servers collection' do
      compute.servers.must_be_kind_of Miasma::Models::Compute::Servers
    end

    describe Miasma::Models::Compute::Servers do

      it 'should provider instance class used within collection' do
        compute.servers.model.must_equal Miasma::Models::Compute::Server
      end

      it 'should build new instance for collection' do
        instance = compute.servers.build(:name => 'test')
        instance.must_be_kind_of Miasma::Models::Compute::Server
      end

      it 'should provide #all servers' do
        VCR.use_cassette("#{cassette_prefix}_servers_all") do
          compute.servers.all.must_be_kind_of Array
        end
      end

    end

  end
}
