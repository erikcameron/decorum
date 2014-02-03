module Decorum
  module Examples
    class ImmediateDecorator < Decorum::Decorator
      immediate 
      share :immediately_shared

      def method_in_question
        "overridden"
      end
      
      def another_method_in_question
        "overridden"
      end

      def increment_immediately_shared
        self.immediately_shared ||= 0
        self.immediately_shared += 1
        decorated_tail(immediately_shared) { next_link.increment_immediately_shared }
      end
    end
  end
end
