module Decorum
  class ChainStop
    def method_missing(*args, &block)
      throw :chain_stop, self
    end
  end
end
