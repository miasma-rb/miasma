describe Miasma::Utils::AnimalStrings do

  it 'should camel case strings' do
    Miasma::Utils.camel('fubar_foobar_fuobar').must_equal 'FubarFoobarFuobar'
  end

  it 'should camel case symbols' do
    Miasma::Utils.camel(:fubar_foobar_fuobar).must_equal 'FubarFoobarFuobar'
  end

  it 'should snake case strings' do
    Miasma::Utils.snake('FubarFoobarFuobar').must_equal 'fubar_foobar_fuobar'
  end

end
