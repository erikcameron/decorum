# decorum/noaliases - this does all of the core setup, everything
# except aliasing public methods in Decorum::Decorations. provided
# separately so users can bypass the alias process entirely if desired.

require 'ostruct'

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

shared_state_class = if class_name = ENV['DECORUM_SHARED_STATE_CLASS']
  current = nil
  class_name.split('::').each do |const_name|
    modyool  = current || Kernel
    current  = modyool.const_get(const_name)
  end
  current
else
  superhash_class
end

module Decorum
end

Decorum::SuperHash    = superhash_class
Decorum::SharedState  = shared_state_class

require_relative 'version'
require_relative 'decorations'
require_relative 'decorator'
require_relative 'decorated_state'
require_relative 'chain_stop'
require_relative 'bare_particular'
require_relative 'callable_decorator'
require_relative 'decorator_namespace'
