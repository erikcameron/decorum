module Decorum
  module Spec
    module Decorator
      class DecoratedStateStub < Decorum::DecoratedState
        def reaching_its_destination?
          true
        end
      end
    end
  end
end
