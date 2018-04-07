describe Miasma::Utils::Smash do
  it "should provide top level constant" do
    defined?(::Smash).wont_be_nil
  end

  it "should provide #to_smash on Hash" do
    Hash.instance_methods.must_include :to_smash
  end

  it "should convert Hash to Smash" do
    {:a => 1}.to_smash.must_equal Smash.new(:a => 1)
  end

  it "should sort keys when converting" do
    hash = {:z => 1, :d => 3, :m => 1}
    smash = Smash.new(:d => 3, :m => 1, :z => 1)
    hash.to_smash.must_equal smash
  end

  it "should convert deep nested Hashes to Smashes" do
    hash = {
      :a => 1,
      :b => [
        {:c => 2},
        {:d => 3},
      ],
    }
    smash = Smash.new(
      :a => 1,
      :b => [
        Smash.new(:c => 2),
        Smash.new(:d => 3),
      ],
    )
    hash.to_smash.must_equal smash
  end

  it "should #get deeply nested value" do
    smash = {
      :a => {
        :b => {
          :c => {
            :d => 1,
          },
        },
      },
    }.to_smash
    smash.get(:a, :b, :c, :d).must_equal 1
  end

  it "should #get nil on missing deeply nested value" do
    smash = {
      :a => {
        :b => {
          :c => {
            :d => 1,
          },
        },
      },
    }.to_smash
    smash.get(:a, :b, :c, :x).must_be_nil
  end

  it "should #set deeply nested value" do
    smash = Smash.new
    smash.set(:a, :b, :c, 1)
    smash.get(:a, :b, :c).must_equal 1
  end

  it "should #fetch default value on missing" do
    smash = {
      :a => {
        :b => {
          :c => {
            :d => 1,
          },
        },
      },
    }.to_smash
    smash.fetch(:a, :b, :c, :x, 1).must_equal 1
  end

  it "should #fetch value when availble" do
    smash = {
      :a => {
        :b => {
          :c => {
            :d => 1,
          },
        },
      },
    }.to_smash
    smash.fetch(:a, :b, :c, :d, 0).must_equal 1
  end

  it "should generate a #checksum" do
    Smash.new(:a => 1).checksum.must_be_kind_of String
  end

  it "should generate equal #checksum" do
    hash = {:z => 1, :d => 3}
    smash = Smash.new(:d => 3, :z => 1)
    hash.to_smash.checksum.must_equal smash.checksum
  end
end
