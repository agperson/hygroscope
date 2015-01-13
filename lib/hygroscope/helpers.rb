require 'hygroscope'
require 'cfoo'

module Hygroscope
  class Helpers
    # Process a set of files with cfoo and return JSON
    def self.process(path)
      out = StringIO.new

      files = Dir.glob(File.join(path, '*.{yml,yaml}'))
      cfoo = Cfoo::Factory.new(out, STDERR).cfoo

      # cfoo's file parser assumes relative paths
      Dir.chdir('/') do
        cfoo.process(*files)
      end

      out.string
    end

    # Process a set of files with cfoo and write JSON to a temporary file
    def self.process_to_file(path)
      file = Tempfile.new(['hygroscope-', '.json'])
      file.write(self.process(path))
      file.close

      at_exit { file.unlink }

      file.path
    end

    # Validate template with AWS and return result
    def self.validate_template(path)
      template = Hygroscope::Helpers.process(File.join(Dir.pwd, 'cfoo'))

      # Parsing the template to JSON and then re-outputting it is a form of
      # compression (removing all extra spaces) to keep within the 50KB limit
      # for CloudFormation templates.
      parsed = JSON.parse(template)

      begin
        cf = Aws::CloudFormation::Client.new
        resp = cf.validate_template(
          template_body: parsed.to_json
        )
      rescue => e
        raise e
      else
        [parsed, resp]
      end
    end

    # Selection list UI element with optional default selection
    def self.select(values, options=nil)
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
