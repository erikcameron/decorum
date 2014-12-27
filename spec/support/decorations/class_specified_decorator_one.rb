module Decorum
  module Spec
    module Decorations
      class ClassSpecifiedDecoratorOne < Decorum::Decorator
        attr_accessor :passed_option
        
        def one
          "one"
        end
      end
    end
  end
end
