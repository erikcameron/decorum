module Decorum
  module Spec
    module Decorator
      class ChattyRootObjectStub 
        def method_missing(*args)
          "root"
        end
      end
    end
  end
end
