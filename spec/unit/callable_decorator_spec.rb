require 'spec_helper'

describe Decorum::CallableDecorator do
  let(:decorator) do 
    c = Decorum::Examples::Coffee.new
    decorator = nil
    c.decorate(Decorum::Examples::MilkDecorator) { |d| decorator = d }
    decorator
  end

  it "enables methods to be called directly on decorators" do
    decorator.add_milk
    expect(decorator.root.milk_level).to eq(1)
  end

  context "testing assumptions" do
    # just make sure we did this right...
    it "is a Decorator" do
      expect(decorator.is_a?(Decorum::CallableDecorator)).to be true
    end
  end
end
