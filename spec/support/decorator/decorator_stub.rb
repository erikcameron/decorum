module Decorum
  module Spec
    module Decorator
      class DecoratorStub 
        def method_missing(*args)
          throw :deferred, self
        end
      end
    end
  end
end
