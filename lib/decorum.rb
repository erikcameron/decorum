require 'ostruct'

module Decorum
  # or Hashr, or whatever---just run the test suite
  class SuperHash < OpenStruct
  end
end

require "decorum/version"
require 'decorum/decorations'
require 'decorum/decorator'
require 'decorum/decorated_state'
require 'decorum/chain_stop'
require 'decorum/bare_particular'
