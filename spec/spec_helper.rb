require './lib/decorum.rb'

Dir.glob("./spec/support/**/*.rb").each { |path| require path }
Dir.glob("./examples/**/*.rb").each { |path| require path }
