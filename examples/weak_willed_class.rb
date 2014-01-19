module Decorum
  module Examples
    class WeakWilledClass
      include Decorum::Decorations

      def method_in_question
        "original"
      end
      
      def method_missing(*args)
        "class method_missing"
      end
    end
  end
end
