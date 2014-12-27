module Decorum
  module Spec
    module Decorations
      class ClassSpecifiedDecoratorTwo < ClassSpecifiedDecoratorOne
        attr_accessor :passed_option
        
        def two 
          "two"
        end
      end
    end
  end
end
