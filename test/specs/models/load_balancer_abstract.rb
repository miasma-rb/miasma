MIASMA_LOAD_BALANCER_ABSTRACT = ->{

  # Required `let`s:
  # * load_balancer: load balancer API
  # * build_args: load balancer build arguments [Smash]
  # * cassette_prefix: cassette file prefix [String]

  describe Miasma::Models::LoadBalancer do

    it 'should provide #balancers collection' do
      load_balancer.balancers.must_be_kind_of Miasma::Models::LoadBalancer::Balancers
    end

    describe Miasma::Models::LoadBalancer::Balancers do

      it 'should provide instance class used within collection' do
        load_balancer.balancers.model.must_equal Miasma::Models::LoadBalancer::Balancer
      end

      it 'should build new instance for collection' do
        instance = load_balancer.balancers.build
        instance.must_be_kind_of Miasma::Models::LoadBalancer::Balancer
      end

      it 'should provide #all balancers' do
        VCR.use_cassette("#{cassette_prefix}_balancers_all") do
          load_balancer.balancers.all.must_be_kind_of Array
        end
      end

    end

    describe Miasma::Models::LoadBalancer::Balancer do

      before do
        @balancer = load_balancer.balancers.build(build_args)
        VCR.use_cassette("#{cassette_prefix}_balancer_before_create") do |obj|
          @balancer.save
          until(@balancer.state == :active)
            sleep(obj.recording? ? 60 : 0.01)
            @balancer.reload
          end
        end
      end

      after do
        VCR.use_cassette("#{cassette_prefix}_balancer_after_destroy") do
          @balancer.destroy
        end
      end

      let(:balancer){ @balancer }

      describe 'collection' do

        it 'should include balancer' do
          load_balancer.balancers.get(balancer.id).wont_be_nil
        end

      end

      describe 'balancer methods' do

        it 'should have a name' do
          balancer.name.must_equal build_args[:name]
        end

        it 'should be in :active state' do
          balancer.state.must_equal :active
        end

        it 'should have a status' do
          balancer.status.wont_be_nil
          balancer.status.must_be_kind_of String
        end

        it 'should have a public address' do
          balancer.public_addresses.wont_be :empty?
        end

      end

    end

  end
}
