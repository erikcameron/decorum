module Decorum
  module Spec
    module Decorations
      class FirstDecorator < Decorum::Decorator
        share :shared_attribute
        attr_accessor :local_attribute
        attr_reader :post_decorated

        def first_decorator_method
          "first"
        end

        alias_method :current_decorator_method, :first_decorator_method

        def respect_previously_defined_methods?
          false
        end
        
        def post_decorate
          @post_decorated = "decorated"
        end
      end
    end
  end
end
