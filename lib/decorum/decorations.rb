module Decorum
  module Decorations
    def self.included(modyool)
      # class method to declare default decorators
      def modyool.decorators(*args)
        # set first-listed priority
        if args[0] == :reverse
          return @_decorum_stack_reverse = true
        end

        @_decorum_stack ||= []

       if !args.empty? 
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
        else
          @_decorum_stack_reverse ? @_decorum_stack.reverse : @_decorum_stack
        end
      end 
    end
  
    # public instance methods

    def _decorum_decorate(klass, options={})
      if namespace_method = options.delete(:namespace)
        decorator = nil
        namespace = nil
        if self.respond_to?(namespace_method)
          namespace = send(namespace_method)
          unless namespace.is_a?(Decorum::DecoratorNamespace)
            raise RuntimeError, "#{namespace_method} exists and is not a decorator namespace"
          end
          namespace._decorum_decorate(klass, options) { |d| decorator = d }
        else
          namespace   = Decorum::DecoratorNamespace.new(self)
          namespace._decorum_decorate(klass, options) { |d| decorator = d }
          instance_variable_set(:"@_decorum_ns_#{namespace_method}", namespace)
          m = Module.new do
            define_method(namespace_method) do
              instance_variable_get(:"@_decorum_ns_#{namespace_method}")
            end
          end
          extend m
          _decorum_namespaces << namespace_method
        end
        yield Decorum::CallableDecorator.new(decorator) if block_given?
      else
        extend Decorum::Decorations::Intercept
        decorator = _add_to_decorum_chain(klass, options)
        yield Decorum::CallableDecorator.new(decorator) if block_given?
        decorator.post_decorate
      end 
      self
    end

    def _decorum_undecorate(target)
      _remove_from_decorum_chain(target)
      self
    end
    
    def _decorum_is_decorated?
      ![ _decorum_decorators, _decorum_namespaces.map { |ns| send(ns)._decorum_decorators } ].flatten.empty?
    end
   
    # returns callable decorators---use this
    def _decorum_decorators
      _decorum_raw_decorators.map { |d| Decorum::CallableDecorator.new(d) }
    end

    # leaving it to you to, say, call this from #initialize
    def _decorum_load_decorators_from_class
      self.class.decorators.each { |decorator_class, options| _decorum_decorate(decorator_class, options) }
      self
    end

    # returns raw decorators---don't use this unless
    # you know what you're doing
    def _decorum_raw_decorators
      # the array of raw decorators is memoized; set
      # @_decorum_raw_decorators to nil/false to rebuild
      if @_decorum_raw_decorators
        return @_decorum_raw_decorators
      elsif !@_decorum_chain_reference
        return []
      end

      # rebuild the array representation of decorators
      decorator = @_decorum_chain_reference
      @_decorum_raw_decorators = []
      until decorator.is_a?(Decorum::ChainStop) 
        @_decorum_raw_decorators << decorator
        decorator = decorator.next_link
      end
      @_decorum_raw_decorators
    end

    # reset the decorator collection
    def _decorum_raw_decorators!
      @_decorum_raw_decorators = nil
      _decorum_raw_decorators
    end

    def _decorum_decorated_state(klass=nil)
      @_decorum_decorated_state ||= {}

      if klass
        @_decorum_decorated_state[klass]
      else
        @_decorum_decorated_state
      end
    end

    def _decorum_namespaces
      @_decorum_namespaces ||= []
    end
 
    module Decorum::Decorations::Intercept
      def method_missing(message, *args, &block)
        response = catch :chain_stop do
          @_decorum_chain_reference.send(message, *args, &block)
        end
        response.is_a?(Decorum::ChainStop) ? super : response
      end
      
      def respond_to_missing?(message, include_private = false)
        _decorum_raw_decorators.each { |d| return true if d.respond_to?(message) }
        super
      end
    end

    private

    def _add_to_decorum_chain(klass, options)
      unless klass.ancestors.include?(Decorum::Decorator)
        raise TypeError, "decorator chain needs a Decorator"
      end

      if options[:decorator_handle]
        current_names = _decorum_raw_decorators.map { |d| d.decorator_handle.to_sym }.compact
        if current_names.include?(options[:decorator_handle].to_sym)
          raise RuntimeError, "decorator names must be unique over an object"
        end
      end

      unless _decorum_decorated_state(klass)
        @_decorum_decorated_state[klass] = Decorum::DecoratedState.new
      end

      base = @_decorum_chain_reference || Decorum::ChainStop.new
      @_decorum_chain_reference = klass.new(base, self, options)

      if klass.immediate_methods
        immediate = Module.new do
          klass.immediate_methods.each do |method_name|
            define_method(method_name) do |*args, &block|
              response = catch :chain_stop do
                @_decorum_chain_reference.send(__method__, *args, &block)
              end
              response.is_a?(Decorum::ChainStop) ? super(*args, &block) : response
            end
          end
        end
        extend immediate
      end
      _decorum_raw_decorators!
      @_decorum_chain_reference
    end

    def _remove_from_decorum_chain(decorator)
      if decorator.is_a?(Decorum::CallableDecorator) 
        decorator = decorator._actual_decorator
      end

      unless (decorator.is_a?(Decorum::Decorator) && _decorum_raw_decorators.include?(decorator))
        return nil
      end

      if decorator == @_decorum_chain_reference
        @_decorum_chain_reference = decorator.next_link
      else
        previous_decorator = _decorum_raw_decorators[_decorum_raw_decorators.index(decorator) - 1]
        previous_decorator.next_link = decorator.next_link
      end
      
      unless _decorum_raw_decorators!.map { |d| d.class }.include?(decorator.class)
        @_decorum_decorated_state[decorator.class] = nil
      end
      _decorum_raw_decorators
    end
  end
end
