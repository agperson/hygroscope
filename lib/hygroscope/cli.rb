require 'hygroscope'

module Hygroscope
  class Cli < Thor
    include Thor::Actions

    def initialize(*args)
      super(*args)
    end

    no_commands do
      def failure(message)
        say_status('error', message, :red)
        abort
      end

      def template_path()
        Dir.pwd
      end

      def template_name()
        File.basename(template_path)
      end

      def check_path()
        unless File.directory?(File.join(Dir.pwd, 'cfoo')) && File.directory?(File.join(Dir.pwd, 'paramsets'))
          failure('Hygroscope must be run from a template directory.')
        end
      end

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

    desc 'create', "Create a new stack.\nUse the name option to launch more than one stack from the same template.\nCommand prompts for parameters unless a paramset is specified."
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
      #puts select(%w(first second third), default: 1)
      #ask("What is your favorite Neopolitan flavor?", :limited_to => %w(strawberry chocolate vanilla))
      #ask("What is your favorite Neopolitan flavor?", :default => 'strawberry' )
    end

    desc 'update', "Update a running stack.\nCommand prompts for parameters unless a paramset is specified."
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
      puts Hygroscope.cfoo_process(File.join(Dir.pwd, 'cfoo'))
    end

    desc 'validate', "Generate JSON from cfoo template files and validate that it is well-formed.\nThis utilzies the CloudFormation API to validate the template but does not detect logical errors."
    def validate()
      check_path
    end

    desc 'params', "List saved paramsets.\nIf name of a paramset is specified with '-n', shows all parameters in the set."
    method_option :name,
      aliases: '-n',
      required: false,
      desc: 'Name of a paramset'
    def params()

    end
  end
end
