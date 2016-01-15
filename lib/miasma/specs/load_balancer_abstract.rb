MIASMA_LOAD_BALANCER_ABSTRACT = ->{

  # Required `let`s:
  # * load_balancer: load balancer API
  # * build_args: load balancer build arguments [Smash]

  describe Miasma::Models::LoadBalancer, :vcr do

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
        load_balancer.balancers.all.must_be_kind_of Array
      end

    end

    describe Miasma::Models::LoadBalancer::Balancer do

      before do
        unless($miasma_balancer)
          VCR.use_cassette('Miasma_Models_LoadBalancer_Global/GLOBAL_load_balancer_create') do
            @balancer = load_balancer.balancers.build(build_args)
            @balancer.save
            until(@balancer.state == :active)
              miasma_spec_sleep
              @balancer.reload
            end
            $miasma_balancer = @balancer
          end
          Kernel.at_exit do
            VCR.use_cassette('Miasma_Models_LoadBalancer_Global/GLOBAL_load_balancer_destroy') do
              $miasma_balancer.destroy
            end
          end
        else
          @balancer = $miasma_balancer
        end
        @balancer.reload
      end

      let(:balancer){ @balancer }

      describe 'collection' do

        it 'should include balancer' do
          load_balancer.balancers.reload.get(balancer.id).wont_be_nil
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
