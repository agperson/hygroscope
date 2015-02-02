require 'hygroscope'

module Hygroscope
  class ParamSetNotFoundError < StandardError
  end

  class ParamSet
    attr_accessor :name, :path
    attr_reader :parameters

    def initialize(name = nil)
      @parameters = {}
      @path = File.join(Dir.pwd, 'paramsets')

      if name
        @name = name
        self.load!
      end
    end

    def load!
      files = Dir.glob(File.join(@path, @name + '.{yml,yaml}'))
      if files.empty?
        fail Hygroscope::ParamSetNotFoundError
      else
        @file = files.first
        @parameters = YAML.load_file(@file)
      end
    end

    def save!
      # If this is a new paramset, construct a filename
      savefile = @file || File.join(@path, @name + '.yaml')
      File.open(savefile, 'w') do |f|
        YAML.dump(@parameters, f)
      end
    end

    def get(key)
      @parameters[key]
    end

    def set(key, value)
      @parameters[key] = value
    end
  end
end
