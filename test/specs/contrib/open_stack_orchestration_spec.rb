require 'miasma/contrib/open_stack'

describe Miasma::Models::Orchestration::OpenStack do

  before do
    @orchestration = Miasma.api(
      :type => :orchestration,
      :provider => :open_stack,
      :credentials => {
        :open_stack_username => ENV['MIASMA_OPENSTACK_USERNAME'],
        :open_stack_password => ENV['MIASMA_OPENSTACK_PASSWORD'],
        :open_stack_identity_url => ENV['MIASMA_OPENSTACK_IDENTITY_URL'],
        :open_stack_tenant_name => ENV['MIASMA_OPENSTACK_TENANT_NAME']
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
          'MiasmaTestInstance' => {
            'type' => 'OS::Nova::Server',
            'properties' => {
              'image' => '8f3e2989-9cff-4f78-a712-61f865669086',
              'flavor' => '1',
              'admin_pass' => 'password'
            }
          }
        }
      },
      :parameters => {
      }
    )
  }
  let(:cassette_prefix){ 'open_stack' }

  instance_exec(&MIASMA_ORCHESTRATION_ABSTRACT)

end
