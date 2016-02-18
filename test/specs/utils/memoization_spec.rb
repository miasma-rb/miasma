require_relative '../../spec.rb'

describe Miasma::Utils::Memoization do

  before do
    @memo = Object.new
    @memo.extend Miasma::Utils::Memoization
  end

  after do
    Thread.current[:bogo_memoization] = nil
  end

  let(:memo){ @memo }

  it 'should #memoize the value returned by block' do
    value = Kernel.rand
    memo.memoize(:test) do
      value
    end.must_equal value
    memo.memoize(:test){ Kernel.rand }.must_equal value
  end

  it 'should not return #memoize value from other instance' do
    memo2 = Object.new
    memo2.extend Miasma::Utils::Memoization
    value = Kernel.rand
    memo.memoize(:test) do
      value
    end.must_equal value
    memo.memoize(:test){ Kernel.rand }.must_equal value
    memo2.memoize(:test){ Kernel.rand }.wont_equal value
  end

  it 'should #unmemoize a memoized value' do
    value = Kernel.rand
    value2 = Kernel.rand
    memo.memoize(:test) do
      value
    end.must_equal value
    memo.unmemoize(:test)
    memo.memoize(:test) do
      value2
    end.must_equal value2
  end

  it 'should allow direct #memoize not restricted to object' do
    memo2 = Object.new
    memo2.extend Miasma::Utils::Memoization
    value = Kernel.rand
    memo.memoize(:test, true) do
      value
    end.must_equal value
    memo.memoize(:test, true){ Kernel.rand }.must_equal value
    memo2.memoize(:test, true){ Kernal.rand }.must_equal value
  end

  it 'should clear all non-direct memoizations with #clear_memoizations!' do
    memo2 = Object.new
    memo2.extend Miasma::Utils::Memoization
    value = Kernel.rand
    memo.memoize(:test, true) do
      value
    end.must_equal value
    memo.memoize(:test){ value }.must_equal value
    memo2.memoize(:test){ value }.must_equal value

    memo.memoize(:test, true){ Kernel.rand }.must_equal value
    memo2.memoize(:test, true){ Kernel.rand }.must_equal value
    memo.memoize(:test){ Kernel.rand }.must_equal value
    memo2.memoize(:test){ Kernel.rand }.must_equal value

    memo.clear_memoizations!
    memo.memoize(:test){ Kernel.rand }.wont_equal value
    memo2.memoize(:test){ Kernel.rand }.must_equal value

    memo2.clear_memoizations!
    memo.memoize(:test){ Kernel.rand }.wont_equal value
    memo2.memoize(:test){ Kernel.rand }.wont_equal value

    memo.memoize(:test, true){ Kernel.rand }.must_equal value
    memo2.memoize(:test, true){ Kernel.rand }.must_equal value
  end

end
