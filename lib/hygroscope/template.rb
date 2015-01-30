require 'hygroscope'
require 'cfoo'

module Hygroscope
  class Template
    attr_reader :path

    def initialize(path)
      @path = path
    end

    # Process a set of files with cfoo and return JSON
    def process
      out = StringIO.new

      files = Dir.glob(File.join(@path, '*.{yml,yaml}'))
      cfoo = Cfoo::Factory.new(out, STDERR).cfoo

      # cfoo's file parser assumes relative paths
      Dir.chdir('/') do
        cfoo.process(*files)
      end

      out.string
    end

    # Process a set of files with cfoo and write JSON to a temporary file
    def process_to_file
      file = Tempfile.new(['hygroscope-', '.json'])
      file.write(self.process(@path))
      file.close

      at_exit { file.unlink }

      file
    end

    def validate
      # Parsing the template to JSON and then re-outputting it is a form of
      # compression (removing all extra spaces) to keep within the 50KB limit
      # for CloudFormation templates.
      template = JSON.parse(self.process)

      begin
        stack = Hygroscope::Stack.new('template-validator')
        resp = stack.client.validate_template(template_body: template.to_json)
      rescue => e
        raise e
      else
        [template, resp]
      end
    end
  end
end
