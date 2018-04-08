require_relative "../../../rspecs"

describe Miasma::Models::Orchestration::Stack::Plan do
  let(:stack) { double("stack", api: api) }
  let(:api) { double("api") }
  let(:subject) { @subject ||= described_class.new(stack) }
  let(:stack_plan) { subject }

  before do
    allow(stack).to receive(:reload)
    allow(stack).to receive(:plan).and_return(stack_plan)
    allow(api).to receive(:stack_reload)
  end

  after do
    @subject = nil
  end

  describe "#apply!" do
    it "should apply the plan to the stack" do
      expect(stack).to receive(:plan_apply)
      subject.apply!
    end

    context "with stale stack plan" do
      let(:stack_plan) { :other }

      it "should raise an error" do
        expect { subject.apply! }.to raise_error(Miasma::Error::OrchestrationError::InvalidStackPlan)
      end
    end
  end

  describe "#destroy" do
    it "should destroy the plan" do
      expect(stack).to receive(:plan_destroy)
      subject.destroy
    end

    context "with stale stack plan" do
      let(:stack_plan) { :other }

      it "should raise an error" do
        expect { subject.destroy }.to raise_error(Miasma::Error::OrchestrationError::InvalidStackPlan)
      end
    end
  end

  describe "#perform_reload" do
    it "should call api to reload plan" do
      expect(api).to receive(:plan_reload).with(subject)
      subject.perform_reload
    end
  end
end
