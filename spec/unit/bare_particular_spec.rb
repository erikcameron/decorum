require 'spec_helper'

describe Decorum::BareParticular do
  let(:bp) { Decorum::BareParticular.new }
  
  it 'is decoratable' do
    expect(bp).to be_a(Decorum::Decorations)
  end

  it 'black holes undefined methods' do
    expect(bp.this_method_absolutely_doesnt_exist).to be_nil
  end
end
