'require spec_helper'

describe 'a Fibonacci sequence implemented in Decorators' do
  let(:fibber) { Decorum::BareParticular.new }

  before(:each) do
    100.times do
      fibber.decorate(Decorum::Examples::FibonacciDecorator)
    end
  end

  it 'returns the 100th term' do 
    expect(fibber.fib).to eq(927372692193078999176)
  end

  it 'stores the sequence' do
    fibber.fib
    expect(fibber.sequence.length).to eq(100)
  end
end
