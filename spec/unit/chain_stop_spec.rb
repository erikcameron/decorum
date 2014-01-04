require 'spec_helper'

describe Decorum::ChainStop do
  let(:chainstop) { Decorum::ChainStop.new }

  it 'throws self via :chain_stop on undefined method' do
    response = catch :chain_stop do 
      chainstop.nonexistent_method
    end
    expect(response).to be_equal(chainstop)
  end
end
