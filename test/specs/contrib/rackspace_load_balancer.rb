require 'miasma/contrib/rackspace'

describe Miasma::Models::LoadBalancer::Rackspace do

  before do
    @load_balancer = Miasma.api(
      :type => :load_balancer,
      :provider => :rackspace,
      :credentials => {
        :rackspace_username => ENV['MIASMA_RACKSPACE_USERNAME'],
        :rackspace_api_key => ENV['MIASMA_RACKSPACE_API_KEY'],
        :rackspace_region => ENV['MIASMA_RACKSPACE_REGION']
      }
    )
  end

  let(:load_balancer){ @load_balancer }
  let(:build_args){ Smash.new(:name => 'miasma-test-load-balancer') }
  let(:cassette_prefix){ 'rackspace_load_balancer' }

  instance_exec(&MIASMA_LOAD_BALANCER_ABSTRACT)

end
