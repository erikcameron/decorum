module Decorum
  module Spec
    module Decorations
      class DecoratedObjectStub
        include Decorum::Decorations
        
        def respect_previously_defined_methods?
          true
        end

        def undecorated_method
          true
        end
      end
    end
  end
end
