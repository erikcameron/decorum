module Decorum
  class DecoratorNamespace
    include Decorum::Decorations

    def initialize(root_object)
      @_root_object = root_object
    end

    def method_missing(message, *args, &block)
      @_root_object.send(message, *args, &block)
    end
  end
end
