require 'spec_helper'

describe Decorum::Decorator do
  let(:decorator) do 
    @next_link = Decorum::ChainStop.new
    @root = Decorum::Spec::Decorator::DecoratedObjectStub.new
    @options_for_decorator = { name: 'bob', shared_attribute: 'shared', overridden_default: true }
    Decorum::Spec::Decorator::BasicDecorator.new(@next_link, @root, @options_for_decorator)
  end

  it 'responds to .share' do
    expect(Decorum::Decorator.respond_to?(:share)).to be_true
  end

  it 'responds to .accumulator' do
    expect(Decorum::Decorator.respond_to?(:accumulator)).to be_true
  end

  it 'responds to .default_attributes' do
    expect(Decorum::Decorator.respond_to?(:default_attributes)).to be_true
  end

  it 'responds to .get_default_attributes' do
    expect(Decorum::Decorator.respond_to?(:get_default_attributes)).to be_true
  end

  it 'responds to .immediate' do
    expect(Decorum::Decorator.respond_to?(:immediate)).to be_true
  end

  it 'responds to .immediate_methods' do
    expect(Decorum::Decorator.respond_to?(:immediate_methods)).to be_true
  end
  
  describe '#decorated_state' do
    it 'defers to the root object' do
      expect(decorator.decorated_state.reaching_its_destination?).to be_true  
    end
  end

  describe '#next_link' do  
    it 'returns the next decorator' do
      expect(decorator.next_link).to be_equal(@next_link)
    end
  end

  describe '#next_link=' do
    it 'sets the next decorator' do
      @new_next_link = Decorum::Spec::Decorator::DecoratorStub.new
      decorator.next_link = @new_next_link
      response = catch :deferred do 
        decorator.send(:nonexistent_method)
      end

      expect(response).to be_equal(@new_next_link)
    end

  describe '#root' do
    it 'returns the root object' do
      expect(decorator.root).to be_equal(@root)
    end

    it 'is aliased as #object' do
      expect(decorator.object).to be_equal(@root)
    end
  end

  describe '#

  describe '#decorated_tail' do
    let(:value) { "howdy" } 
    
    it 'catches :chain_stop' do
      response = decorator.decorated_tail(value) { throw :chain_stop, "caught" }
      expect(response).to eq("caught")
    end

    it 'preserves return value' do 
      response = decorator.decorated_tail(value) { decorator.send(:nonexistent_method) }
      expect(response).to eq(value)
    end
  end
  
  context 'when attributes are declared default' do
    describe '#getter' do
      it 'gets default value' do
        expect(decorator.first_default).to eq("default value")
      end
      
      it 'is overridden by options passed to initialize' do
        expect(decorator.overridden_default).to equal(true)
      end
    end
    
    describe '#setter' do 
      it 'gets defined' do
        decorator.first_default = "new value"
        expect(decorator.first_default).to eq("new value")
      end
    end
  end
        
  context 'when attributes are declared via share' do
    describe '#setter' do
      it 'does not set attribute locally' do
        expect(decorator.instance_variable_get(:@shared_attribute)).to be_nil
      end

      it 'sets attribute in shared state' do 
        expect(decorator.decorated_state.shared_attribute).to eq('shared')
      end
    end

    describe '#getter' do
      it 'sets attribute' do
        expect(decorator.shared_attribute).to eq('shared')
      end

      it 'gets nil for unused attribute' do
        expect(decorator.unused_shared_attribute).to be_nil
      end
    end

    describe '#boolean' do
      it 'returns true on set attribute' do
        expect(decorator.shared_attribute?).to equal(true)
      end

      it 'returns false on unset attribute' do
        expect(decorator.unused_shared_attribute?).to equal(false)
      end
    end

    describe '#resetter' do
      before(:each) { decorator.reset_shared_attribute }
     
      it 'sets attribute to nil' do
        expect(decorator.shared_attribute).to be_nil
      end

      it 'sets attribute to nil in shared state' do
        decorator.instance_variable_set(:@shared_attribute, "for real not nil")
        expect(decorator.shared_attribute).to be_nil
      end
    end 
  end

  context 'when attributes are declared personally' do
    describe '#setter' do
      it 'sets local attribute via initialize' do
        expect(decorator.name).to eq('bob')
      end
    
      it 'sets local attribute locally by initialize' do
        expect(decorator.instance_variable_get(:@name)).to eq('bob')
      end

      it 'does not set local attribute in shared state via initialize' do
        expect(decorator.decorated_state.name).to be_nil
      end
    end

    describe '#getter' do
      it 'gets nil for unused attribute' do
        expect(decorator.unused_personal_attribute).to be_nil
      end
    end
  end
  
  context 'when calling decorator methods' do
    it 'picks up methods it has' do
      expect(decorator.basic_decorator_method).to be_true
    end

    it 'defers methods it doesn\'t have' do
      response = catch :chain_stop do 
        decorator.send(:nonexistent_method) 
      end
      expect(response).to be_a(Decorum::ChainStop)
    end
  end
  
  context 'when methods are declared immediate' do
    it 'includes them in @immediate_methods' do
      expect(Decorum::Examples::StrongWilledDecorator.immediate_methods.include?(:method_in_question)).to be_true
    end
    
    it 'respects various forms of declaration' do
      # i.e.:
      # - it respects mulitple immediate declarations
      # - it respects single methods or an array of methods
      # see Examples::StrongWilledDecorator
      methods = ["second", "third", "fourth"].map do |pre|
        "#{pre}_immediate_method".to_sym
      end

      got_em = methods.map { |m| Decorum::Examples::StrongWilledDecorator.immediate_methods.include?(m) }.inject(:&)
      expect(got_em).to be_true
    end
  end
end
