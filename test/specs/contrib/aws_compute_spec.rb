require 'miasma/contrib/aws'

describe Miasma::Models::Compute::Aws do

  before do
    @compute = Miasma.api(
      :type => :compute,
      :provider => :aws,
      :credentials => {
        :aws_access_key_id => ENV['MIASMA_AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['MIASMA_AWS_SECRET_ACCESS_KEY'],
        :aws_region => ENV['MIASMA_AWS_REGION']
      }
    )
  end

  let(:compute){ @compute }
  let(:build_args){
    Smash.new(
      :name => 'miasma-test-instance',
      :image_id => ENV['MIASMA_AWS_IMAGE'],
      :flavor_id => ENV['MIASMA_AWS_FLAVOR'],
      :key_name => 'default'
    )
  }
  let(:cassette_prefix){ 'aws' }

  instance_exec(&MIASMA_COMPUTE_ABSTRACT)

end
