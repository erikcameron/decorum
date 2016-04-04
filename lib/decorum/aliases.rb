# Here we alias public methods defined by Decorum::Decorations, 
# because these will appear in other people's classes and should
# therefore not cause conflcts. Public methods:
#   _decorum_decorate
#   _decorum_undecorate
#   _decorum_is_decorated?
#   _decorum_decorators
#   _decorum_decorated_state
#   _decorum_load_decorators_from_class
#
# and these three more "internal" methods, no default aliases:
#   _decorum_raw_decorators
#   _decorum_raw_decorators!
#   _decorum_namespaces
#
# you can also specify a capitalized method name in env for 
# something other than default, e.g., 
#
#   _DECORUM_DECORATE='my_funky_decorate_alias' 
#
# otherwise it will fall back on defaults; to bypass this 
# entirely load decorum/noaliases

module Decorum
  module Decorations
    module ClassMethods
      class_method_alias = ENV['_DECORUM_CLASS_DECORATORS'] || "decorators"
      alias_method class_method_alias, :decorum
    end

    DEFAULT_ALIASES = { _decorum_decorate: "decorate",
      _decorum_undecorate: "undecorate",
      _decorum_is_decorated?: "is_decorated?",
      _decorum_decorators: "decorators",
      _decorum_decorated_state: "decorated_state",
      _decorum_load_decorators_from_class: "load_decorators_from_class",
      _decorum_raw_decorators: nil,
      _decorum_raw_decorators!: nil,
      _decorum_namespaces: nil }


    DEFAULT_ALIASES.each do |k, v|
      aliased_name = ENV["#{k.upcase}"] || v
      if aliased_name
        alias_method aliased_name, k
      end
    end
  end
end
        
