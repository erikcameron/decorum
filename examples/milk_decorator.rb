module Decorum
  module Examples
    class MilkDecorator < Decorum::Decorator
      share :milk_level, :calories
      attr_accessor :animal, :milk_type

      # recursive function to allow all MilkDecorators to add
      # some milk; note the tail call is wrapped in decorated_tail
      def add_milk
        self.milk_level = milk_level.to_i + 1
        decorated_tail(milk_level) { next_link.add_milk }
      end
      
      # used with non-shared attributes, (e.g., "animal")
      # decorated tail can also be used to defer a
      # call to the _first_ decorator in the chain 
      # that responds to the method
      def first_animal
        decorated_tail(animal) { next_link.first_animal }
      end

      # for goodness' sake what has bob been putting in his coffee
      def all_animals(animals=[])
        animals << animal
        decorated_tail(animals) { next_link.all_animals(animals) }
      end
    end
  end
end
