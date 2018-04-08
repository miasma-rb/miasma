require_relative "../../rspecs"

describe Miasma::Models::Orchestration do
  let(:subject) { described_class.new({}) }

  before do
    allow_any_instance_of(described_class).to receive(:custom_setup)
    allow_any_instance_of(described_class).to receive(:load_data)
    allow_any_instance_of(described_class).to receive(:after_setup)
    allow_any_instance_of(described_class).to receive(:connect)
  end
  after { subject.clear_memoizations! }

  describe "#stacks" do
    it "should load stacks on first call" do
      expect(Miasma::Models::Orchestration::Stacks).to receive(:new)
      subject.stacks
    end

    it "should not load stacks on second call" do
      expect(Miasma::Models::Orchestration::Stacks).to receive(:new)
      subject.stacks
      expect(Miasma::Models::Orchestration::Stacks).not_to receive(:new)
      subject.stacks
    end
  end

  describe "#stack_save" do
    it "should raise not implemented error" do
      expect { subject.stack_save(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_reload" do
    it "should raise not implemented error" do
      expect { subject.stack_reload(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_destroy" do
    it "should raise not implemented error" do
      expect { subject.stack_destroy(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_all" do
    it "should raise not implemented error with argument" do
      expect { subject.stack_all(nil) }.to raise_error(NotImplementedError)
    end

    it "should raise not implemented error without argument" do
      expect { subject.stack_all }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_template_load" do
    it "should raise not implemented error" do
      expect { subject.stack_template_load(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_template_validate" do
    it "should raise not implemented error" do
      expect { subject.stack_template_validate(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_plan" do
    it "should raise not implemented error" do
      expect { subject.stack_plan(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#stack_all" do
    it "should raise not implemented error" do
      expect { subject.stack_all(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#resource_all" do
    it "should raise not implemented error" do
      expect { subject.resource_all(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#resource_reload" do
    it "should raise not implemented error" do
      expect { subject.resource_reload(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#event_all" do
    it "should raise not implemented error" do
      expect { subject.event_all(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#event_all_new" do
    it "should raise not implemented error" do
      expect { subject.event_all_new(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#event_reload" do
    it "should raise not implemented error" do
      expect { subject.event_reload(nil) }.to raise_error(NotImplementedError)
    end
  end
end
