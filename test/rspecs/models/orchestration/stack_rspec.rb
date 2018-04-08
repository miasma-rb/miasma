require_relative "../../../rspecs"

describe Miasma::Models::Orchestration::Stack do
  let(:api) { double("api") }
  let(:stack_name) { "DEFAULT_STACK_NAME" }
  let(:stack_opts) { @stack_opts ||= {:name => stack_name} }
  let(:subject) { @subject ||= described_class.new(api, stack_opts) }

  before { allow(api).to receive(:stack_reload) }

  after do
    @subject = nil
    @stack_opts = nil
  end

  describe "#name" do
    context "with no stack name defined" do
      let(:stack_name) { nil }

      it "should raise an error" do
        expect { subject.load_data }.to raise_error(ArgumentError)
      end
    end

    context "with name defined as non string value" do
      let(:stack_name) { :custom_name }

      it "should raise an error" do
        expect { subject.load_data }.to raise_error(TypeError)
      end
    end

    it "should return the stack name" do
      expect(subject.name).to eq(stack_name)
    end
  end

  describe "#plan" do
    it "should automatically call plan loading" do
      expect(subject).to receive(:perform_plan)
      subject.plan
    end

    context "with invalid planning state" do
      before { stack_opts[:state] = :delete_complete }

      it "should raise an error" do
        expect { subject.plan }.to raise_error(
          Miasma::Error::OrchestrationError::InvalidPlanState
        )
      end
    end

    context "with valid planning state" do
      before { stack_opts[:state] = :create_complete }

      it "should generate plan" do
        expect(api).to receive(:stack_plan).with(subject)
        subject.plan
      end
    end
  end

  describe "#plans" do
    it "should load plans" do
      expect(Miasma::Models::Orchestration::Stack::Plans).to receive(:new).with(subject)
      subject.plans
    end
  end

  describe "#plan_apply" do
    context "without generated plan" do
      it "should raise an error" do
        expect { subject.plan_apply }.to raise_error(
          Miasma::Error::OrchestrationError::InvalidStackPlan
        )
      end
    end

    context "with generated plan" do
      before { allow(subject).to receive(:dirty?).with(:plan).and_return(true) }
      it "should apply the plan" do
        expect(subject).to receive(:perform_plan_apply)
        subject.plan_apply
      end
    end
  end

  describe "#plan_delete" do
    context "without generated plan" do
      it "should raise an error" do
        expect { subject.plan_delete }.to raise_error(
          Miasma::Error::OrchestrationError::InvalidStackPlan
        )
      end
    end

    context "with generated plan" do
      before { allow(subject).to receive(:dirty?).with(:plan).and_return(true) }
      it "should apply the plan" do
        expect(subject).to receive(:perform_plan_delete)
        subject.plan_delete
      end
    end
  end
end
