module Decorum
  module Decorations
    def decorate(klass, options={})
      extend Decorum::Decorations::Intercept
      decorator = add_to_decorator_chain(klass, options)
      yield decorator if block_given?
      self
    end

    def undecorate(target)
      remove_from_decorator_chain(target)
      self
    end

    def decorators
      if @_decorators
        return @_decorators
      elsif !@_decorator_chain
        return []
      end

      decorator = @_decorator_chain
      @_decorators = []
      until decorator.is_a?(Decorum::ChainStop) 
        @_decorators << decorator
        decorator = decorator.next_link
      end
      @_decorators
    end

    def decorated_state(klass=nil)
      @_decorated_state ||= {}

      if klass
        @_decorated_state[klass]
      else
        @_decorated_state
      end
    end
 
    module Decorum::Decorations::Intercept
      def method_missing(message, *args, &block)
        response = catch :chain_stop do
          @_decorator_chain.send(message, *args, &block)
        end
        response.is_a?(Decorum::ChainStop) ? super : response
      end
      
      def respond_to_missing?(message, include_private = false)
        decorators.each { |d| return true if d.respond_to?(message) }
        super
      end
    end

    protected

    def add_to_decorator_chain(klass, options)
      unless klass.ancestors.include?(Decorum::Decorator)
        raise RuntimeError.new("decorator chain needs a Decorator")
      end

      if options[:decorator_handle]
        current_names = decorators.map { |d| d.decorator_handle.to_sym }.compact
        if current_names.include?(options[:decorator_handle].to_sym)
          # is this a little harsh?
          raise RuntimeError.new("decorator names must be unique over an object")
        end
      end

      unless decorated_state(klass)
        @_decorated_state[klass] = Decorum::DecoratedState.new
      end

      base = @_decorator_chain || Decorum::ChainStop.new
      @_decorator_chain = klass.new(base, self, options)
      decorators!
      @_decorator_chain
    end

    def remove_from_decorator_chain(decorator)
      return nil unless decorators.include?(decorator) 

      if decorator == @_decorator_chain
        @_decorator_chain = decorator.next_link
      else
        previous_decorator = decorators[decorators.index(decorator) - 1]
        previous_decorator.next_link = decorator.next_link
      end
      
      unless decorators!.map { |d| d.class }.include?(decorator.class)
        @_decorated_state[decorator.class] = nil
      end
      decorators
    end

    def decorators!
      @_decorators = nil
      decorators
    end
  end
end
