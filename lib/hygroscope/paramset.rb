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

      return unless name

      @name = name
      load!
    end

    def load!
      files = Dir.glob(File.join(@path, @name + '.{yml,yaml}'))

      raise Hygroscope::ParamSetNotFoundError if files.empty?

      @file = files.first
      @parameters = YAML.load_file(@file)
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

    def set(key, value, use_previous_value: false)
      @parameters[key] = if use_previous_value
                           'HYGROSCOPE_USE_PREVIOUS_VALUE'
                         else
                           value
                         end
    end
  end
end
