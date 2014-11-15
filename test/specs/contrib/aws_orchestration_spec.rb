require 'miasma/contrib/aws'

describe Miasma::Models::Orchestration::Aws do

  before do
    @orchestration = Miasma.api(
      :type => :orchestration,
      :provider => :aws,
      :credentials => {
        :aws_access_key_id => ENV['MIASMA_AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['MIASMA_AWS_SECRET_ACCESS_KEY'],
        :aws_region => ENV['MIASMA_AWS_REGION']
      }
    )
  end

  let(:orchestration){ @orchestration }
  let(:build_args){
    Smash.new(
      :name => 'miasma-test-stack',
      :template => {
        'AWSTemplateFormatVersion' => '2010-09-09',
        'Description' => 'Miasma test stack',
        'Resources' => {
          'MiasmaTestHandle' => {
            'Type' => 'AWS::CloudFormation::WaitConditionHandle'
          }
        }
      },
      :parameters => {
      }
    )
  }
  let(:cassette_prefix){ 'aws' }

  instance_exec(&MIASMA_ORCHESTRATION_ABSTRACT)

end
