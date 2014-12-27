module Decorum
  module Decorations
    def self.included(modyool)
      # class method to declare default decorators
      def modyool.decorators(*args, &block)
        # set first-listed priority
        if args[0] == :reverse
          return @_decorum_stack_reverse = true
        end

        @_decorum_stack ||= []

       if !args.empty? || block_given?
          args.each do |arg|
            if (arg.is_a?(Class) && arg.ancestors.include?(Decorum::Decorator)) || arg.is_a?(Hash)
              next if arg.is_a?(Hash)
              klass     = arg
              next_arg  = args[args.index(arg) + 1]
              options   = next_arg.is_a?(Hash) ? next_arg : {}
              @_decorum_stack << [klass, options]
            else
              raise ArgumentError, "invalid argument to #{self.to_s}.decorate_with: #{arg.to_s}"
            end
          end

          # is this block syntax really necessary? consider removing?
          if block_given?
            block.arity == 0 ? instance_eval(&block) : yield(self)
          end
        else
          @_decorum_stack_reverse ? @_decorum_stack.reverse : @_decorum_stack
        end
      end 
    end
  
    # instance methods

    # leaving it to you to, say, call this from #initialize
    def load_decorators_from_class
      self.class.decorators.each { |decorator_class, options| decorate(decorator_class, options) }
      self
    end

    def decorate(klass, options={})
      if namespace_method = options.delete(:namespace)
        decorator = nil
        namespace = nil
        if self.respond_to?(namespace_method)
          namespace = send(namespace_method)
          unless namespace.is_a?(Decorum::DecoratorNamespace)
            raise RuntimeError, "#{namespace_method} exists and is not a decorator namespace"
          end
          namespace.decorate(klass, options) { |d| decorator = d }
        else
          namespace = Decorum::DecoratorNamespace.new(self)
          namespace.decorate(klass, options) { |d| decorator = d }
          instance_variable_set(:"@_decorum_#{namespace_method}", namespace)
          m = Module.new do
            define_method(namespace_method) do
              instance_variable_get(:"@_decorum_#{namespace_method}")
            end
          end
          extend m
        end
        yield CallableDecorator.new(decorator) if block_given?
      else
        extend Decorum::Decorations::Intercept
        decorator = add_to_decorator_chain(klass, options)
        yield CallableDecorator.new(decorator) if block_given?
        decorator.post_decorate
      end 
      self
    end

    def undecorate(target)
      remove_from_decorator_chain(target)
      self
    end

    
    # returns callable decorators---use this
    def decorators
      _decorators.map { |d| CallableDecorator.new(d) }
    end

    # returns raw decorators---don't use this unless
    # you know what you're doing
    def _decorators
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

    # reset the decorator collection
    def _decorators!
      @_decorators = nil
      _decorators
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
        _decorators.each { |d| return true if d.respond_to?(message) }
        super
      end
    end

    protected

    def add_to_decorator_chain(klass, options)
      unless klass.ancestors.include?(Decorum::Decorator)
        raise TypeError, "decorator chain needs a Decorator"
      end

      if options[:decorator_handle]
        current_names = _decorators.map { |d| d.decorator_handle.to_sym }.compact
        if current_names.include?(options[:decorator_handle].to_sym)
          raise RuntimeError, "decorator names must be unique over an object"
        end
      end

      unless decorated_state(klass)
        @_decorated_state[klass] = Decorum::DecoratedState.new
      end

      base = @_decorator_chain || Decorum::ChainStop.new
      @_decorator_chain = klass.new(base, self, options)

      if klass.immediate_methods
        immediate = Module.new do
          klass.immediate_methods.each do |method_name|
            define_method(method_name) do |*args, &block|
              response = catch :chain_stop do
                @_decorator_chain.send(__method__, *args, &block)
              end
              response.is_a?(Decorum::ChainStop) ? super(*args, &block) : response
            end
          end
        end
        extend immediate
      end
      _decorators!
      @_decorator_chain
    end

    def remove_from_decorator_chain(decorator)
      if decorator.is_a?(CallableDecorator) 
        decorator = decorator.instance_variable_get(:@_decorator)
      end

      unless (decorator.is_a?(Decorum::Decorator) && _decorators.include?(decorator))
        return nil
      end

      if decorator == @_decorator_chain
        @_decorator_chain = decorator.next_link
      else
        previous_decorator = _decorators[_decorators.index(decorator) - 1]
        previous_decorator.next_link = decorator.next_link
      end
      
      unless _decorators!.map { |d| d.class }.include?(decorator.class)
        @_decorated_state[decorator.class] = nil
      end
      _decorators
    end
  end
end
