require_relative "../../../rspecs"

describe Miasma::Models::Orchestration::Stack::Plans do
  let(:stack) { double("stack", api: api) }
  let(:api) { double("api") }
  let(:subject) { @subject ||= described_class.new(stack) }

  before { allow(api).to receive(:stack_reload) }

  after do
    @subject = nil
  end

  describe "#stack" do
    it "should return linked stack" do
      expect(subject.stack).to eq(stack)
    end
  end

  describe "#filter" do
    it "should raise error" do
      expect { subject.filter }.to raise_error(NotImplementedError)
    end
  end

  describe "#build" do
    it "should create a new plan" do
      expect(Miasma::Models::Orchestration::Stack::Plan).to receive(:new)
      subject.build
    end

    it "should create a new plan linked to stack" do
      expect(Miasma::Models::Orchestration::Stack::Plan).to receive(:new).with(stack, any_args)
      subject.build
    end
  end

  describe "#model" do
    it "should be Plan" do
      expect(subject.model).to eq(Miasma::Models::Orchestration::Stack::Plan)
    end
  end
end
