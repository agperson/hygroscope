require 'hygroscope'
require 'cfoo'

module Hygroscope
  class CloudFormation
    def initialize
      @client = Aws::CloudFormation::Client.new
    end

    # Process a set of files with cfoo and return JSON
    def process(path)
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
    def process_to_file(path)
      file = Tempfile.new(['hygroscope-', '.json'])
      file.write(self.process(path))
      file.close

      at_exit { file.unlink }

      file.path
    end

    # Validate template with AWS and return result
    def validate_template(path)
      template = self.process(File.join(Dir.pwd, 'cfoo'))

      # Parsing the template to JSON and then re-outputting it is a form of
      # compression (removing all extra spaces) to keep within the 50KB limit
      # for CloudFormation templates.
      parsed = JSON.parse(template)

      begin
        resp = @client.validate_template(
          template_body: parsed.to_json
        )
      rescue => e
        raise e
      else
        [parsed, resp]
      end
    end

    def delete_stack(stack)
      begin
        @client.delete_stack(stack_name: stack)
      rescue => e
        raise e
      end
    end

    def describe_stack(stack)
      begin
        resp = @client.describe_stacks(stack_name: stack)
      rescue => e
        raise e
      else
        resp.stacks.first
      end
    end

    def list_stack_resources(stack)
      begin
        resp = @client.describe_stack_resources(stack_name: stack)
      rescue => e
        raise e
      else
        resources = []
        resp.stack_resources.each do |r|
          resources << {
            name: r.logical_resource_id,
            type: r.resource_type,
            status: r.resource_status
          }
        end

        resources
      end
    end
  end
end
