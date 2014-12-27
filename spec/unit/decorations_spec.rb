require 'spec_helper'

describe Decorum::Decorations do
  let(:decorated) { Decorum::Spec::Decorations::DecoratedObjectStub.new }
  let(:deco_class_1) { Decorum::Spec::Decorations::FirstDecorator }
  let(:deco_class_2) { Decorum::Spec::Decorations::SecondDecorator }
  let(:deco_class_3) { Decorum::Spec::Decorations::ThirdDecorator }

  context 'loading decorators from class defaults' do
    let(:klass) do 
      Class.new do
        include Decorum::Decorations
        decorators Decorum::Spec::Decorations::ClassSpecifiedDecoratorOne, { passed_option: "one" },
          Decorum::Spec::Decorations::ClassSpecifiedDecoratorTwo, { passed_option: "two" }
      end
    end

    describe '.decorators' do
      it 'stores decorators in own state correctly' do
        expect(klass.decorators.map { |d| d[0].ancestors.include?(Decorum::Decorator) }.inject(:&)).to be_true
      end

      # the instance method #load_decorators_from_class will insert them in the order given:
      
      it 'normally gives first priority to last listed' do
        expect(klass.decorators.map { |d| d[1] } == [{ passed_option: "one" }, { passed_option: "two" }]).to be_true
      end

      it 'reverses order for first-specfied priority' do
        klass.decorators :reverse
        expect(klass.decorators.map { |d| d[1] } == [{ passed_option: "two" }, { passed_option: "one" }]).to be_true
      end

      it 'rejects malformed options' do
        expect { klass.decorators(Decorum::Spec::Decorations::FirstDecorator, "invalid decorator argument") }.to raise_error
      end

      # this probably belongs with other instance methods below, but we've got the 
      # support objects built for it here...
      describe '#decorators' do 
        let(:obj) { klass.new.load_decorators_from_class }
        it 'returns self' do
          # sort of
          expect(obj.is_a?(klass)).to be_true
        end

        it 'loads all decorators given by .decorators' do
          expect(obj.one == "one" && obj.two == "two").to be_true
        end

        it 'loads decorators in the order given by .decorators' do
          expect(obj.passed_option == "two").to be_true
        end
      end
    end
  end

  context 'as-yet-undecorated' do 
    # assert some basic assumptions
    it 'is decoratable' do
      expect(decorated.is_a?(Decorum::Decorations)).to be_true
    end

    it 'does not respond to first decorator test method' do
      expect(decorated.respond_to?(:first_decorator_method)).to be_false
    end

    it 'responds to its own methods' do 
      expect(decorated.undecorated_method).to be_true
    end

    describe '#decorated_state' do
      it 'returns a hash' do
        blank_state = decorated.decorated_state
        expect(blank_state.is_a?(Hash)).to be_true
      end

      it 'returns an empty hash' do
        blank_state = decorated.decorated_state
        expect(blank_state.empty?).to be_true
      end

      it 'returns nil given an argument' do
        expect(decorated.decorated_state(:not_gonna_work)).to be_nil
      end
    end
    
    describe 'undecorate' do
      it 'returns self on symbol' do
        expect(decorated.undecorate(:symbol_arg)).to be_equal(decorated)
      end

      it 'returns self on spurious decorator' do
        expect(decorated.undecorate(deco_class_1)).to be_equal(decorated)
      end
    end
  end

  context 'decorated' do
    describe '#decorate' do
      it 'returns self on decoration' do
        real_decorated = decorated
        expect(decorated.decorate(deco_class_1)).to be_equal(real_decorated)
      end

      it 'calls #post_decorate' do
        expect(decorated.decorate(deco_class_1).post_decorated).to eq("decorated")
      end
      
      it 'yields decorator if block_given?' do
        decorator = nil
        decorated.decorate(deco_class_1) { |dec| decorator = dec }
        actual_decorator = decorated.instance_variable_get(:@_decorator_chain)
        expect(decorator.instance_variable_get(:@_decorator)).to be(actual_decorator)
      end
       
      context 'success' do 
        before(:each) do
          decorator_options = { decorator_handle: "first", shared_attribute: "shared 1", local_attribute: "local 1" }
          decorated.decorate(deco_class_1, decorator_options)
        end

        it 'installs intercept' do
          expect(decorated.is_a?(Decorum::Decorations::Intercept)).to be_true
        end

        it 'sets internal state' do
          internal_state = decorated.instance_variable_get(:@_decorator_chain)
          expect(internal_state.is_a?(deco_class_1)).to be_true
        end

        it 'does not lose its own methods' do
          expect(decorated.respect_previously_defined_methods?).to be_true
        end
        
        it 'gains the methods of the decorator' do
          expect(decorated.first_decorator_method).to eq('first')
        end

        it 'raises NoMethodError on nonexistent method' do
          expect { decorated.nonexistent_method }.to raise_error(NoMethodError)
        end
        
        it 'is decorated by local attributes' do
          expect(decorated.local_attribute).to eq("local 1")
        end

        it 'is decorated by shared attributes' do
          expect(decorated.shared_attribute).to eq("shared 1")
        end

        it 'creates decorated state for decorator class' do
          expect(decorated.decorated_state(deco_class_1).shared_attribute).to eq('shared 1')
        end
      
        context 'with multiple decorators' do
          before(:each) do
            3.times do |i|
              klass = send(:"deco_class_#{i + 1}")
              decorated.decorate(klass)
            end
          end

          it 'retains decorated methods' do
            responses = [:first, :second, :third].map do |prefix|
              decorated.send(:"#{prefix}_decorator_method") 
            end
            expect(responses).to eq(["first", "second", "third"])
          end
          
          it 'prefers the most recent decorator' do
            expect(decorated.current_decorator_method).to eq("third")
          end
        end
      end

      context 'failure' do
        it 'rejects classes that are not Decorators' do
          expect { decorated.decorate(Class,{}) }.to raise_error(TypeError)
        end

        it 'rejects non unique decorator handles' do
          3.times do |i|
            klass = send(:"deco_class_#{i + 1}")
            decorated.decorate(klass, decorator_handle: "deco-#{i + 1}")
          end
          expect { decorated.decorate(deco_class_1, decorator_handle: "deco-2") }.to raise_error(RuntimeError)
        end
      end
    end
    
    describe '#respond_to?' do
      before(:each) { decorated.decorate(deco_class_1) }

      it 'returns true for decorated methods' do  
        expect(decorated.respond_to?(:first_decorator_method)).to be_true
      end

      it 'returns true for undecorated methods' do
        expect(decorated.respond_to?(:undecorated_method)).to be_true
      end

      it 'returns false for undefined method' do
        expect(decorated.respond_to?(:nonexistent_method)).to be_false
      end
    end

    context 'monitoring and unloading' do
      before(:each) do
        3.times do |x|
          klass = send(:"deco_class_#{x + 1}")
          decorated.decorate(klass, decorator_handle: "deco-#{x + 1}")
        end
      end

      describe '#decorators' do
        it 'accurately reflects loaded decorators and in order' do
          expected_map = ["deco-3", "deco-2", "deco-1"]
          expect(decorated.decorators.map { |d| d.decorator_handle }).to eq(expected_map)
        end

        it 'memoizes decorators' do
          decorated.decorators[0].next_link = decorated.decorators[2]
          expect(decorated.decorators.length).to be(3)
        end

        it 'refreshes via #decorators!' do
          decorated._decorators[0].next_link = decorated._decorators[2]
          decorated.send(:_decorators!)
          expect(decorated.decorators.length).to be(2)
        end
      end

      describe '#undecorate' do 
        before(:each) do
          @undec = decorated.decorators.detect { |d| d.decorator_handle == "deco-2" }
          # just to make sure...
          unless @undec.is_a?(Decorum::CallableDecorator)
            raise "broken test---no such decorator deco-2; undec was #{@undec.inspect}"
          end
        end

        it 'undecorates' do
          decorated.undecorate(@undec)
          expect(decorated.decorators.length).to be(2)
        end

        it 'undecorates the right one' do
          decorated.undecorate(@undec)
          expected_map = ["deco-3", "deco-1"]
          expect(decorated.decorators.map { |d| d.decorator_handle }).to eq(expected_map)
        end

        it 'returns self on success' do
          real_decorated = decorated
          expect(decorated.undecorate(@undec)).to be_equal(real_decorated)
        end
        
        context 'once undecorated' do
          before(:each) { decorated.undecorate(@undec) }

          it 'no longer responds to removed decorated method' do
            expect(decorated.respond_to?(:second_decorator_method)).to be_false
          end

          it 'still responds to other decorated methods' do 
            expect(decorated.respond_to?(:third_decorator_method)).to be_true
          end

          it 'doesn\'t mind if we check one just to be sure' do
            expect(decorated.first_decorator_method).to eq('first')
          end

          it 'destroys shared state when last class member is gone' do
            expect(decorated.decorated_state(deco_class_2)).to be_nil
          end

          it 'does not destroy other shared state' do
            expect(decorated.decorated_state(deco_class_1)).to be_a(Decorum::DecoratedState)
          end
        end 
      end
    end
  end
end
