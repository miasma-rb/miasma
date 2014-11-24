require 'miasma/contrib/open_stack'

describe Miasma::Models::Compute::OpenStack do

  before do
    @compute = Miasma.api(
      :type => :compute,
      :provider => :open_stack,
      :credentials => {
        :open_stack_username => ENV['MIASMA_OPENSTACK_USERNAME'],
        :open_stack_password => ENV['MIASMA_OPENSTACK_PASSWORD'],
        :open_stack_identity_url => ENV['MIASMA_OPENSTACK_IDENTITY_URL'],
        :open_stack_tenant_name => ENV['MIASMA_OPENSTACK_TENANT_NAME']
      }
    )
  end

  let(:compute){ @compute }
  let(:build_args){
    Smash.new(
      :name => 'miasma-test-instance',
      :image_id => ENV['MIASMA_OPENSTACK_IMAGE'],
      :flavor_id => ENV['MIASMA_OPENSTACK_FLAVOR']
    )
  }
  let(:cassette_prefix){ 'open_stack' }

  instance_exec(&MIASMA_COMPUTE_ABSTRACT)

end
