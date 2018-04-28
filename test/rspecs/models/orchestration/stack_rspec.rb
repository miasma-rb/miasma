require_relative "../../../rspecs"

describe Miasma::Models::Orchestration::Stack do
  let(:api) { double("api") }
  let(:stack_name) { "DEFAULT_STACK_NAME" }
  let(:stack_opts) { @stack_opts ||= {:name => stack_name} }
  let(:subject) { @subject ||= described_class.new(api, stack_opts) }

  before do
    allow(api).to receive(:stack_reload)
    allow(api).to receive(:stack_plan_load)
  end

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
      expect(subject).to receive(:load_plan)
      subject.plan
    end
  end

  describe "#plan_generate" do
    context "with invalid planning state" do
      before { stack_opts[:state] = :delete_complete }

      it "should raise an error" do
        expect { subject.plan_generate }.to raise_error(
          Miasma::Error::OrchestrationError::InvalidPlanState
        )
      end
    end

    context "with valid planning state" do
      before { stack_opts[:state] = :create_complete }

      it "should generate plan" do
        expect(api).to receive(:stack_plan).with(subject)
        subject.plan_generate
      end
    end
  end

  describe "#plans" do
    it "should load plans" do
      expect(Miasma::Models::Orchestration::Stack::Plans).to receive(:new).with(subject)
      subject.plans
    end
  end

  describe "#plan_execute" do
    context "without generated plan" do
      it "should raise an error" do
        expect { subject.plan_execute }.to raise_error(
          Miasma::Error::OrchestrationError::InvalidStackPlan
        )
      end
    end

    context "with generated plan" do
      before { allow(subject).to receive(:dirty?).with(:plan).and_return(true) }
      it "should execute the plan" do
        expect(subject).to receive(:perform_plan_execute)
        subject.plan_execute
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
      it "should execute the plan" do
        expect(subject).to receive(:perform_plan_delete)
        subject.plan_delete
      end
    end
  end
end
