require 'hygroscope'
require 'pp'

module Hygroscope
  class Cli < Thor
    include Thor::Actions

    def initialize(*args)
      super(*args)
    end

    no_commands do
      def fail(message)
        say_status('error', message, :red)
        abort
      end

      def template_path()
        Dir.pwd
      end

      def template_name()
        File.basename(template_path)
      end

      def paramset(name)
        files = Dir.glob(File.join(template_path, 'paramsets', options[:name] + '.{yml,yaml}'))
        fail("Paramlist `#{options[:name]}' does not exist.") if files.empty?

        content = YAML.load_file(files.first)
        fail("No parameters for `#{template_name}' paramlist `#{options[:name]}'.") unless content

        content
      end

      def check_path()
        unless File.directory?(File.join(Dir.pwd, 'cfoo')) && File.directory?(File.join(Dir.pwd, 'paramsets'))
          fail('Hygroscope must be run from a template directory.')
        end
      end
    end

    desc 'create', "Create a new stack.\nUse the --name option to launch more than one stack from the same template.\nCommand prompts for parameters unless --paramset is specified."
    method_option :name,
      aliases: '-n',
      default: File.basename(Dir.pwd),
      desc: 'Name of stack'
    method_option :paramset,
      aliases: '-p',
      required: false,
      desc: 'Name of saved paramset to use (optional)'
    method_option :ask,
      aliases: '-a',
      type: :boolean,
      default: false,
      desc: 'Still prompt for parameters even when using a paramset'
    def create()
      check_path
      begin
        t, resp = Hygroscope::Helpers.validate_template(File.join(Dir.pwd, 'cfoo'))
      rescue
        fail 'Template is not valid, run `validate\' command for more information.'
      end

      #puts select(%w(first second third), default: 1)
      #ask("What is your favorite Neopolitan flavor?", :limited_to => %w(strawberry chocolate vanilla))
      #ask("What is your favorite Neopolitan flavor?", :default => 'strawberry' )
    end

    desc 'update', "Update a running stack.\nCommand prompts for parameters unless a --paramset is specified."
    method_option :name,
      aliases: '-n',
      default: File.basename(Dir.pwd),
      desc: 'Name of stack'
    method_option :paramset,
      aliases: '-p',
      required: false,
      desc: 'Name of saved paramset to use (optional)'
    method_option :ask,
      aliases: '-a',
      type: :boolean,
      default: false,
      desc: 'Still prompt for parameters even when using a paramset'
    def update()
      check_path
    end

    desc 'delete', 'Delete a running stack after asking for confirmation.'
    method_option :name,
      aliases: '-n',
      default: File.basename(Dir.pwd),
      desc: 'Name of stack'
    method_option :force,
      aliases: '-f',
      type: :boolean,
      default: false,
      desc: 'Delete without asking for confirmation'
    def delete()
      check_path
      puts yes?("Really delete stack #{options[:name]} [y/N]?")
    end


    desc 'generate', "Generate and display JSON output from cfoo template files.\nTo validate that the template is well-formed use the 'validate' command."
    def generate()
      check_path
      puts Hygroscope::Helpers.process(File.join(Dir.pwd, 'cfoo'))
    end

    desc 'validate', "Generate JSON from cfoo template files and validate that it is well-formed.\nThis utilzies the CloudFormation API to validate the template but does not detect logical errors."
    def validate()
      check_path
      begin
        _t, _resp = Hygroscope::Helpers.validate_template(File.join(Dir.pwd, 'cfoo'))
      rescue Aws::CloudFormation::Errors::ValidationError => e
        say 'Validation error:', :red
        print_wrapped e.message, indent: 2
        abort
      rescue => e
        say 'Unexpected error:', :red
        print_wrapped e.message, indent: 2
        abort
      else
        say 'Template is valid!', :green
      end
    end

    desc 'params', "List saved paramsets.\nIf --name is passed, shows all parameters in the named set."
    method_option :name,
      aliases: '-n',
      required: false,
      desc: 'Name of a paramset'
    def params()
      if options[:name]
        content = paramset(options[:name])
        say "Parameters for `#{template_name}' paramset `#{options[:name]}':", :yellow
        print_table content, indent: 2
      else
        files = Dir.glob(File.join(template_path, 'paramsets', '*.{yml,yaml}'))
        if files.empty?
          say "No saved paramsets for `#{template_name}'."
        else
          say "Saved paramsets for `#{template_name}':", :yellow
          files.map do |f|
            say "  " + File.basename(f, File.extname(f))
          end
        end
      end
    end
  end
end
