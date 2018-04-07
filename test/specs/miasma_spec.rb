require_relative "../spec.rb"

describe Miasma do
  it "should provide an #api entry method" do
    Miasma.respond_to?(:api).must_equal true
  end

  describe "Miasma.api" do
    it "should require `:type` argument" do
      lambda do
        Miasma.api(:provider => "", :credentials => {})
      end.must_raise ArgumentError
    end

    it "should require `:provider` argument" do
      lambda do
        Miasma.api(:type => "", :credentials => {})
      end.must_raise ArgumentError
    end

    it "should fail to load unknown provider" do
      lambda do
        Miasma.api(:provider => :unknown, :type => :compute, :credentials => {})
      end.must_raise Miasma::Error
    end
  end
end
