module Decorum
  class DecoratedState 
    def initialize(options={})
      @shared_state = Decorum::SuperHash.new(options)
    end

    # this is one of two areas---the other being
    # loading/unloading of decorators---where i
    # suspect it isn't threadsafe now, but could
    # pretty easily be made to be, e.g., in the 
    # writer forwarder below:
    #
    #   lock = Monitor.new
    #   lock.synchronize do
    #     @state.send(message, *args)
    #   end
    # 
    # more on this some other time.
    def method_missing(message, *args)
      if message =~ /=$/
        # writer, in case we want to do something different here
        @shared_state.send(message, *args)
      else
        # reader
        @shared_state.send(message, *args)
      end
    end
  end
end
