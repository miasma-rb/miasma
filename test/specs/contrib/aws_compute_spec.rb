require 'miasma/contrib/aws'
require_relative '../models/compute_abstract'

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
  let(:cassette_prefix){ 'aws_compute' }

  instance_exec(&MIASMA_COMPUTE_ABSTRACT)

end
