MIASMA_COMPUTE_ABSTRACT = ->{

  # Required `let`s:
  # * compute: compute API
  # * build_args: server build arguments [Smash]

  describe Miasma::Models::Compute, :vcr do

    it 'should provide #servers collection' do
      compute.servers.must_be_kind_of Miasma::Models::Compute::Servers
    end

    describe Miasma::Models::Compute::Servers do

      it 'should provide instance class used within collection' do
        compute.servers.model.must_equal Miasma::Models::Compute::Server
      end

      it 'should build new instance for collection' do
        instance = compute.servers.build(:name => 'test')
        instance.must_be_kind_of Miasma::Models::Compute::Server
      end

      it 'should provide #all servers' do
        compute.servers.all.must_be_kind_of Array
      end

    end

    describe Miasma::Models::Compute::Server do

      before do
        @instance = compute.servers.build(build_args)
        @instance.save
        until(@instance.state == :running)
          sleep(20)
          @instance.reload
        end
      end

      after do
        @instance.destroy
      end

      let(:instance){ @instance }

      describe 'instance methods' do

        it 'should have a name' do
          instance.name.must_equal build_args[:name]
        end

        it 'should have an image_id' do
          instance.image_id.must_equal build_args[:image_id]
        end

        it 'should have a flavor_id' do
          instance.flavor_id.must_equal build_args[:flavor_id]
        end

        it 'should have an address' do
          instance.addresses.detect do |addr|
            addr.version == 4
          end.address.must_match /^(\d+)+\.(\d+)\.(\d+)\.(\d+)$/
        end

        it 'should have a status' do
          instance.status.wont_be_nil
        end

        it 'should be in :running state' do
          instance.state.must_equal :running
        end

      end

    end

    describe 'instance lifecycle' do
      it 'should create new server, reload details and destroy server' do
        instance = compute.servers.build(build_args)
        instance.save
        instance.id.wont_be_nil
        instance.state.must_equal :pending
        compute.servers.reload.get(instance.id).wont_be_nil
        until(instance.state == :running)
          sleep(obj.recording? ? 60 : 0.01)
          instance.reload
        end
        instance.state.must_equal :running
        instance.destroy
        while(instance.state == :running)
          sleep(obj.recording? ? 10 : 0.01)
          instance.reload
        end
        [:pending, :terminated].must_include instance.state
        if(instance.state == :pending)
          until(instance.state == :terminated)
            sleep(obj.recording? ? 60 : 0.01)
            instance.reload
          end
          instance.state.must_equal :terminated
        end
      end

    end

  end
}
