module Decorum
  module Spec
    module DecoratedState
      class SharedStateStub
        def marker=(*args)
          "assigned"
        end

        def marker
          "retrieved"
        end
      end
    end
  end
end
