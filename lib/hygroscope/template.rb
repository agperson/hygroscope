require 'hygroscope'
require 'cfoo'

module Hygroscope
  class TemplateYamlParseError < StandardError
  end

  class Template
    attr_reader :path

    def initialize(path)
      @path = path
    end

    # Process a set of files with cfoo and return JSON
    def process
      return @template if @template

      out = StringIO.new
      err = StringIO.new

      files = Dir.glob(File.join(@path, '*.{yml,yaml}'))
      cfoo = Cfoo::Factory.new(out, err).cfoo

      Dir.chdir('/') do
        cfoo.process(*files)
      end

      fail(TemplateYamlParseError, err.string) unless err.string.empty?

      @template = out.string
      @template
    end

    def compress
      JSON.parse(process).to_json
    end

    def parameters
      template = JSON.parse(process)
      template['Parameters'] || []
    end

    # Process a set of files with cfoo and write JSON to a temporary file
    def process_to_file
      file = Tempfile.new(['hygroscope-', '.json'])
      file.write(process)
      file.close

      at_exit { file.unlink }

      file
    end

    def validate
      # Parsing the template to JSON and then re-outputting it is a form of
      # compression (removing all extra spaces) to keep within the 50KB limit
      # for CloudFormation templates.
      template = compress

      begin
        stack = Hygroscope::Stack.new('template-validator')
        stack.client.validate_template(template_body: template)
      rescue => e
        raise e
      end
    end
  end
end
