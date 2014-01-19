module Decorum
  module Examples
    class StrongWilledDecorator < Decorum::Decorator
      immediate :method_in_question
      immediate :second_immediate_method, :third_immediate_method
      immediate :fourth_immediate_method

      def method_in_question
        "overridden"
      end
      
      def second_immediate_method
        "method dos"
      end
      
      def third_immediate_method
        "method tres"
      end

      def fourth_immediate_method
        "method quatro"
      end
    end
  end
end
