require 'thor'
require 'hygroscope'

module Hygroscope
  class Cli < Thor
    def initialize(*args)
      super(*args)
    end

    desc 'process <dir>', 'Run cfoo on <dir>'
    def process(dir=nil)
      dir = Dir.pwd if dir.nil?
      Hygroscope.process(dir)
    end
  end
end


#ask(“What is your name?”)
#ask(“What is your favorite Neopolitan flavor?”, :limited_to => [“strawberry”, “chocolate”, “vanilla”])
#ask(“What is your password?”, :echo => false)
#ask(“Where should the file be saved?”, :path => true)
#y = yes?(statement)
