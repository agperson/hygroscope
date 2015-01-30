require 'hygroscope'

module Hygroscope
  class ParamSetNotFoundError < StandardError
  end

  class ParamSet
    attr_accessor :path
    attr_reader :name

    def initialize(name)
      @name = name
      @path = File.join(Dir.pwd, 'paramsets')
    end

    def parameters
      unless @parameters
        files = Dir.glob(File.join(@path, @name + '.{yml,yaml}'))
        if files.empty?
          raise Hygroscope::ParamSetNotFoundError
        else
          @parameters = YAML.load_file(files.first)
        end
      end

      @parameters
    end
  end
end
