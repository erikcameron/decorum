module Decorum
  module Examples
    class SugarDecorator < Decorum::Decorator
      share :sugar_level

      def add_sugar
        self.sugar_level = sugar_level.to_i + 1
        decorated_tail(sugar_level) { decoratee.add_cube }
      end
    end
  end
end
