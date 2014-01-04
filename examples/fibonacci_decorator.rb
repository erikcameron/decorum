module Decorum
  module Examples
    class FibonacciDecorator < Decorum::Decorator
      accumulator :sequence
      accumulator :current

      def fib(a = nil, b = nil)
        unless a && b
          reset_current
          self.sequence = []
          a = 1
          b = 1
        end

        self.current = a + b
        self.sequence << current
        
        decorated_tail(current) do
          next_link.fib(b, current)
        end
      end
    end
  end
end
