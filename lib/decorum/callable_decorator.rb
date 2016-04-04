module Decorum
  class CallableDecorator
    def initialize(decorator)
      @_decorator = decorator
    end

    # tortuously named to avoid conflict and discourage use
    def _actual_decorator
      @_decorator
    end
    
    def method_missing(message, *args, &block)
      response = catch :chain_stop do
        @_decorator.send(message, *args, &block)
      end
      if response.is_a?(Decorum::ChainStop)
        @_decorator.root.send(message, *args, &block)
      else
        response
      end
    end
  end
end
