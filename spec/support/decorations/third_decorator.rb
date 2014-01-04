module Decorum
  module Spec
    module Decorations
      class ThirdDecorator < Decorum::Decorator
        share :shared_attribute
        attr_accessor :local_attribute

        def third_decorator_method
          "third"
        end

        alias_method :current_decorator_method, :third_decorator_method

        def respect_previously_defined_methods?
          false
        end
      end
    end
  end
end
