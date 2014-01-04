module Decorum
  module Spec
    module Decorations
      class SecondDecorator < Decorum::Decorator
        share :shared_attribute
        attr_accessor :local_attribute

        def second_decorator_method
          "second"
        end

        alias_method :current_decorator_method, :second_decorator_method

        def respect_previously_defined_methods?
          false
        end
      end
    end
  end
end
