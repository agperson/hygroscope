require 'hygroscope'

module Hygroscope
  class ParamSet
    def initialize
    end

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
  end
end
