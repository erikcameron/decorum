require 'spec_helper'

describe "when Bob is ordering a cup of coffee" do
  let(:coffee) { Decorum::Examples::Coffee.new }

  before(:each) do
    coffee._decorum_decorate(Decorum::Examples::MilkDecorator, animal: "cow", milk_type: "2 percent")
    coffee._decorum_decorate(Decorum::Examples::MilkDecorator, animal: "cow", milk_type: "2 percent")
    coffee._decorum_decorate(Decorum::Examples::SugarDecorator)
    coffee.add_milk
    coffee.add_sugar
  end
  
  it 'adds up to two milks' do
    expect(coffee.milk_level).to be(2)
  end

  it 'has a sugar too' do
    expect(coffee.sugar_level).to be(1)
  end

  context "things get interesting" do
    before(:each) do 
      ["bear", "man", "pig"].each do |critter|
        coffee._decorum_decorate(Decorum::Examples::MilkDecorator, animal: critter)
      end
      coffee.add_milk 
    end
    
    it 'gets another squirt from those original two cow milks' do
      # just so we're clear on how this works---you have to clear
      # the shared state yourself
      expect(coffee.milk_level).to be(7)
    end

    it 'details Bob\'s dairy proclivities' do
      expected_animals = ["pig", "man", "bear", "cow", "cow"]
      expect(coffee.all_animals).to eq(expected_animals)
    end
  end
end
