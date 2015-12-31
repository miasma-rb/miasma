MIASMA_ORCHESTRATION_ABSTRACT = ->{

  # Required `let`s:
  # * orchestration: orchestration API
  # * build_args: stack build arguments [Smash]

  describe Miasma::Models::Orchestration, :vcr do

    it 'should provide #stacks collection' do
      orchestration.stacks.must_be_kind_of Miasma::Models::Orchestration::Stacks
    end

    describe Miasma::Models::Orchestration::Stacks do

      it 'should provide instance class used within collection' do
        orchestration.stacks.model.must_equal Miasma::Models::Orchestration::Stack
      end

      it 'should build new instance for collection' do
        instance = orchestration.stacks.build
        instance.must_be_kind_of Miasma::Models::Orchestration::Stack
      end

      it 'should provide #all stacks' do
        orchestration.stacks.all.must_be_kind_of Array
      end

    end

    describe Miasma::Models::Orchestration::Stacks do

      before do
        unless($miasma_stack)
          VCR.use_cassette('Miasma_Models_Orchestration_Aws/GLOBAL_orchestration_stack_create') do
            @stack = orchestration.stacks.build(build_args)
            @stack.save
            until(@stack.state == :create_complete)
              miasma_spec_sleep
              @stack.reload
            end
            @stack.template
            orchestration.stacks.reload
            $miasma_stack = @stack
          end
          Kernel.at_exit do
            VCR.use_cassette('Miasma_Models_Compute_Aws/GLOBAL_orchestration_stack_destroy') do
              $miasma_stack.destroy
            end
          end
        else
          @stack = $miasma_stack
        end
        @stack.reload
      end

      let(:stack){ @stack }

      describe 'collection' do

        it 'should include stack' do
          orchestration.stacks.all.detect{|s| s.id == stack.id}.wont_be_nil
          orchestration.stacks.get(stack.id).wont_be_nil
        end

      end

      describe 'instance methods' do

        it 'should have a name' do
          stack.name.must_equal build_args[:name]
        end

        it 'should be in :create_complete state' do
          stack.state.must_equal :create_complete
        end

        it 'should have a status' do
          stack.status.must_be_kind_of String
        end

        it 'should have a creation time' do
          stack.created.must_be_kind_of Time
        end

        it 'should have parameters used for creation' do
          stack.parameters.to_smash.must_equal build_args[:parameters].to_smash
        end

        it 'should include the templated used for creation' do
          stack.template.to_smash.must_equal build_args[:template].to_smash
        end

      end

    end

    describe 'instance lifecycle' do
      it 'should create new stack, reload details and destroy stack' do
        stack = orchestration.stacks.build(build_args.merge(:name => 'miasma-test-stack-2'))
        stack.save
        stack.id.wont_be_nil
        stack.state.must_equal :create_in_progress
        orchestration.stacks.reload.get(stack.id).wont_be_nil
        until(stack.state == :create_complete)
          miasma_spec_sleep
          stack.reload
        end
        stack.state.must_equal :create_complete
        stack.destroy
        [:delete_in_progress, :delete_complete].must_include stack.state
        until(stack.state == :delete_complete)
          miasma_spec_sleep
          stack.reload
        end
        stack.state.must_equal :delete_complete
      end

    end

  end
}
