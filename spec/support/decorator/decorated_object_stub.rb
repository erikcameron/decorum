module Decorum
  module Spec
    module Decorator
      class DecoratedObjectStub
        include Decorum::Decorations
        
        def respect_previously_defined_methods?
          true
        end
        
        def _decorum_decorated_state(*args)
          @_decorum_decorated_state ||= Decorum::Spec::Decorator::DecoratedStateStub.new
        end
      end
    end
  end
end
