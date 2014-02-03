require 'spec_helper'

describe Decorum::DecoratorCollection do
  let(:collection) { Decorum::DecoratorCollection.new(1) }

  describe "#callable" do
    it "responds to #callable" do
      expect(collection.respond_to?(:callable)).to be_true
    end

    it "returns callable decorators" do
      expect(collection.callable.first.is_a?(Decorum::CallableDecorator)).to be_true
    end
  end
end
