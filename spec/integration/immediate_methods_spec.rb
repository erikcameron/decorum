require 'spec_helper'

describe "When overriding original methods with .immediate" do
  let(:base_object) { Decorum::Examples::WeakWilledClass.new }

  it "has an original method" do
    expect(base_object.method_in_question).to eq("original")
  end

  it "overrides original methods" do
    base_object._decorum_decorate(Decorum::Examples::StrongWilledDecorator)
    expect(base_object.method_in_question).to eq("overridden")
  end

  it "reverts to original method when decorator is unloaded" do
    base_object._decorum_decorate(Decorum::Examples::StrongWilledDecorator)
    base_object._decorum_undecorate(base_object._decorum_decorators.first)
    expect(base_object.method_in_question).to eq("original")
  end

  it "stops chain on vanished method" do
    base_object._decorum_decorate(Decorum::Examples::StrongWilledDecorator)
    # raise on violated assumptions rather than have multiple conditions in the same test?
    resp =  base_object.second_immediate_method 
    unless resp == "method dos"
      bail_message = "Bad test data: base_object doesn't have #second_immediate_method, got #{resp}"
      raise bail_message
    end

    base_object._decorum_undecorate(base_object._decorum_decorators.first)
    expect(base_object.second_immediate_method).to eq("class method_missing")
  end

  it "recurses" do
    4.times { base_object._decorum_decorate(Decorum::Examples::ImmediateDecorator) }
    expect(base_object.increment_immediately_shared).to eq(4)
  end

  it "recurses on namespaced decorator" do
    4.times { base_object._decorum_decorate(Decorum::Examples::ImmediateDecorator, namespace: :foo) }
    expect(base_object.foo.increment_immediately_shared).to eq(4)
  end
end
