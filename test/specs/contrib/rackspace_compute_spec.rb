require 'miasma/contrib/rackspace'

describe Miasma::Models::Compute::Rackspace do

  before do
    @compute = Miasma.api(
      :type => :compute,
      :provider => :rackspace,
      :credentials => {
        :rackspace_username => ENV['MIASMA_RACKSPACE_USERNAME'],
        :rackspace_api_key => ENV['MIASMA_RACKSPACE_API_KEY'],
        :rackspace_region => ENV['MIASMA_RACKSPACE_REGION']
      }
    )
  end

  let(:compute) do
    if(Thread.current[:miasma_memoization])
      Thread.current[:miasma_memoization].delete_if do |k,v|
        k.to_s.start_with?('rackspace')
      end
    end
    VCR.use_cassette('rackspace_identity_seed') do
      @compute.servers.all
    end
    @compute
  end

  let(:build_args){
    Smash.new(
      :name => 'miasma-test-instance',
      :image_id => ENV['MIASMA_RACKSPACE_IMAGE'],
      :flavor_id => ENV['MIASMA_RACKSPACE_FLAVOR'],
      :key_name => 'default'
    )
  }
  let(:cassette_prefix){ 'rackspace' }

  instance_exec(&MIASMA_COMPUTE_ABSTRACT)

end
