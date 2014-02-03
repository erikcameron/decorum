require 'spec_helper'

describe Decorum::SuperHash do
  let(:soop) { Decorum::SuperHash.new(a: "z", b: "y", c: "x") }

  it "accepts a hash" do
    expect(soop.a).to eq("z")
  end
  
  it "returns nil on nonexistent methods" do
    expect(soop.asdfasdfasd).to be_nil
  end
  
  context "after initialization" do
    it "has working setters" do
      soop.d = "w"
      expect(soop.d).to eq("w")
    end
  end
end
