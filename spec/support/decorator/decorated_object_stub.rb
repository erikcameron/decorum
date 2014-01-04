module Decorum
  module Spec
    module Decorator
      class DecoratedObjectStub
        include Decorum::Decorations
        
        def respect_previously_defined_methods?
          true
        end
        
        def decorated_state(*args)
          @decorated_state ||= Decorum::Spec::Decorator::DecoratedStateStub.new
        end
      end
    end
  end
end
