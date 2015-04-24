require 'spec_helper'

describe Decorum::DecoratorNamespace do
  let(:root)          { Decorum::Spec::Decorator::DecoratedObjectStub.new }
  let(:chatty_root)   { Decorum::Spec::Decorator::ChattyRootObjectStub.new }
  let(:ns_class)      { Decorum::DecoratorNamespace }

  it "is decoratable" do
    ns = ns_class.new(root)
    expect(ns.is_a?(Decorum::Decorations)).to be true
  end
  
  it "defers to root object on unknown messages" do
    ns = ns_class.new(chatty_root)
    expect(ns.asdfasdfadf).to eq("root")
  end
end
