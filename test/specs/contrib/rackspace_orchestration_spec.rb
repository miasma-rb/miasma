require 'miasma/contrib/rackspace'

describe Miasma::Models::Orchestration::Rackspace do

  before do
    @orchestration = Miasma.api(
      :type => :orchestration,
      :provider => :rackspace,
      :credentials => {
        :rackspace_username => ENV['MIASMA_RACKSPACE_USERNAME'],
        :rackspace_api_key => ENV['MIASMA_RACKSPACE_API_KEY'],
        :rackspace_region => ENV['MIASMA_RACKSPACE_REGION']
      }
    )
  end

  let(:orchestration){ @orchestration }
  let(:build_args){
    Smash.new(
      :name => 'miasma-test-stack',
      :template => {
        'heat_template_version' => '2013-05-23',
        'resources' => {
          'MiasmaSubNet' => {
            'type' => 'Rackspace::Cloud::Network',
            'properties' => {
              'cidr' => '192.168.233.0/24',
              'label' => 'miasma auto test network'
            }
          }
        }
      },
      :parameters => {
      }
    )
  }
  let(:cassette_prefix){ 'rackspace' }

  instance_exec(&MIASMA_ORCHESTRATION_ABSTRACT)

end
