require 'spec_helper'

describe Decorum::DecoratedState do
  let(:ds) { Decorum::DecoratedState.new(foo: "bar") }
  
  it 'assigns initialized options' do
    expect(ds.foo).to eq("bar")
  end

  context 'when forwarding messages' do
    before(:each) do
      # need to pop it open first...
      fake_shared_state = Decorum::Spec::DecoratedState::SharedStateStub.new
      ds.instance_variable_set(:@shared_state, fake_shared_state)
    end

    it 'forwards getter methods' do
      expect(ds.marker).to eq("retrieved")
    end

    it 'forwards setter methods' do
      expect(ds.send(:"marker=", 'foo')).to eq('assigned')
    end

    describe '#respond_to?' do
      it 'is false for forwarded messages' do
        expect(ds.respond_to?(:marker)).to be_false
      end
    end 
  end
end
