require 'thor'
require 'fileutils'
require 'tempfile'
require 'yaml'
require 'aws-sdk'

require_relative 'hygroscope/cli'
require_relative 'hygroscope/stack'
require_relative 'hygroscope/template'
require_relative 'hygroscope/paramset'
require_relative 'hygroscope/payload'

    # Selection list UI element with optional default selection
    def select(values, options=nil)
      print_table values.map.with_index{ |a, i| [i + 1, *a]}

      if !options.nil? && options[:default]
        selection = ask('Selection:', default: options[:default]).to_i
      else
        selection = ask('Selection:').to_i
      end

      values[selection - 1]
    end
