require 'miasma/contrib/aws'

describe Miasma::Models::Storage::Aws do

  before do
    @storage = Miasma.api(
      :type => :storage,
      :provider => :aws,
      :credentials => {
        :aws_access_key_id => ENV['MIASMA_AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['MIASMA_AWS_SECRET_ACCESS_KEY'],
        :aws_region => ENV['MIASMA_AWS_REGION']
      }
    )
  end

  let(:storage){ @storage }
  let(:cassette_prefix){ 'aws' }

  instance_exec(&MIASMA_STORAGE_ABSTRACT)

end
