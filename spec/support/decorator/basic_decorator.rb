module Decorum
  module Spec
    module Decorator
      class BasicDecorator < Decorum::Decorator
        default_attributes first_default: "default value", overridden_default: false

        share :shared_attribute, :unused_shared_attribute
        attr_accessor :name, :unused_personal_attribute

        def basic_decorator_method
          true
        end

        def respect_previously_defined_methods?
          false
        end
      end
    end
  end
end
