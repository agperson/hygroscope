require 'hygroscope'

module Hygroscope
  class ParamSetNotFoundError < StandardError
  end

  class ParamSet
    attr_accessor :name, :path
    attr_reader :paramset

    def initialize(name=nil)
      @paramset = Hash.new
      @path = File.join(Dir.pwd, 'paramsets')

      if name
        @name = name
        self.load!
      end
    end

    def load!
      files = Dir.glob(File.join(@path, @name + '.{yml,yaml}'))
      if files.empty?
        raise Hygroscope::ParamSetNotFoundError
      else
        @file = files.first
        @paramset = YAML.load_file(@file)
      end
    end

    def save!
      # If this is a new paramset, construct a filename
      savefile = @file || File.join(@path, @name + '.yaml')
      File.open(savefile, 'w') do |f|
        YAML.dump(@paramset, f)
      end
    end

    def get(key)
      @paramset[key]
    end

    def set(key, value)
      @paramset[key] = value
    end
  end
end
