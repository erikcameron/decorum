module Decorum
  class Decorator
    attr_accessor :next_link
    attr_reader :root, :decorator_handle
    alias_method :object, :root

    def initialize(next_link, root, options)
      @passed_options = options
      @next_link = next_link
      @root = root
      @decorator_handle = options[:decorator_handle]

      defaults = self.class.get_default_attributes
      attribute_options = defaults ? defaults.merge(options) : options

      attribute_options.each do |key, value|
        setter = :"#{key}="
        if respond_to?(setter)
          send setter, value
        end
      end
    end
    
    # override if you want
    def post_decorate
      nil
    end

    # a superhash of shared state between Decorators
    # of the same class
    def decorated_state
      root.decorated_state(self.class)
    end

    # Decorators that want stackable or cumulative 
    # behavior can do so with tail recursion. Wrap
    # the tail call in #decorated_tail to catch the
    # end of the chain and return the accumulator
    def decorated_tail(current_value=nil, &block)
      response = catch :chain_stop do
        yield
      end
      response.is_a?(Decorum::ChainStop) ? current_value : response
    end
    alias_method :defer, :decorated_tail

    # delegate to next_link
    # note that we are not faking #respond_to? because
    # we want that to reflect what the decorator can
    # respond to locally
    def method_missing(*args, &block)
      @next_link.send(*args, &block)
    end

    # class methods
    class << self
      # allow Decorator classes to share state among
      # their instances
      def share(*args)
        args.each do |getter|
          getter = getter.to_sym
          define_method(getter) { self.decorated_state.send(getter) }

          boolean = :"#{getter}?"
          define_method(boolean) { self.decorated_state.send(getter) ? true : false }

          setter = :"#{getter}="
          define_method(setter) { |value| self.decorated_state.send(setter, value) }
          
          resetter = :"reset_#{getter}"
          define_method(resetter) { self.decorated_state.send(setter, nil) }
        end
      end
      
      # hint as to how one might use these attributes
      alias_method :accumulator, :share

      # allow Decorator classes to provide attribute defaults (not shared)
      def default_attributes(attrs)
        @default_attributes = attrs
        attrs.keys.each do |attr|
          attr_accessor attr.to_sym
        end
      end

      def get_default_attributes
        @default_attributes || {}
      end
      
      # allow Decorator classes to override the decorated object's
      # public methods; use with no args to declare the entire interface 
      def immediate(*method_names)
        if method_names.empty?
          @all_immediate = true
        else
          @immediate_methods ||= []
          @immediate_methods += method_names
        end
      end

      def immediate_methods
        @all_immediate ? instance_methods(false) : (@immediate_methods || [])
      end
    end
  end
end
