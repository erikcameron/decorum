# decorum.rb
require ENV['DECORUM_SUPERHASH_REQUIRE'] || 'ostruct'
superhash_class = if class_name = ENV['DECORUM_SUPERHASH_CLASS']
  current = nil
  class_name.split('::').each do |const_name|
    modyool  = current || Kernel
    current  = modyool.const_get(const_name)
  end
  current
else
  OpenStruct
end

module Decorum
end

Decorum::SuperHash = superhash_class

require_relative 'decorum/version'
require_relative 'decorum/decorations'
require_relative 'decorum/decorator'
require_relative 'decorum/decorated_state'
require_relative 'decorum/chain_stop'
require_relative 'decorum/bare_particular'
require_relative 'decorum/callable_decorator'
require_relative 'decorum/decorator_collection'
require_relative 'decorum/decorator_namespace'
