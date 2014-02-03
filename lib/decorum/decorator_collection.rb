module Decorum
  class DecoratorCollection < Array
    def callable
      map { |decorator| Decorum::CallableDecorator.new(decorator) }
    end
  end
end
