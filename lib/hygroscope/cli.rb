require 'hygroscope'

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

      def colorize_status(status)
        case status.downcase
          when /failed$/
            set_color(status, :red)
          when /progress$/
            set_color(status, :yellow)
          when /complete$/
            set_color(status, :green)
        end
      end

      def word_wrap(string, length = 80, delim = $/)
        string.scan(/.{#{length}}|.+/).map { |x| x.strip }.join(delim)
      end

      def countdown(text, time=5)
        print "#{text}  "
        time.downto(0) do |i|
          $stdout.write("\b")
          $stdout.write(i)
          $stdout.flush
          sleep 1
        end
      end

      def check_path
        unless File.directory?(File.join(Dir.pwd, 'template')) && File.directory?(File.join(Dir.pwd, 'paramsets'))
          fail('Hygroscope must be run from the top level of a hygroscopic directory.')
        end
      end

      def hygro_path
        Dir.pwd
      end

      def hygro_name
        File.basename(Dir.pwd)
      end

      def template_path
        File.join(hygro_path, 'template')
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
      validate

      # Generate the template
      t = Hygroscope::Template.new(template_path)

      # If the paramset exists load it, otherwise instantiate an empty one
      p = Hygroscope::ParamSet.new(options[:paramset])

      # TODO: Load and merge outputs from previous invocations -- how???

      # User provided a paramset, so load it and determine which parameters
      # are set and which need to be prompted.
      if options[:paramset]
        pkeys = p.paramset.keys
        tkeys = t.parameters.keys

        # Filter out any parameters that are not present in the template
        filtered = pkeys - tkeys
        pkeys = pkeys.select { |k,v| tkeys.include?(k) }
        say_status('info', "Keys in paramset not requested by template: #{filtered.join(', ')}", :blue) unless filtered.empty?

        # If ask option was passed, consider every parameter missing
        missing = options[:ask] ? tkeys : tkeys - pkeys
      else
        # No paramset provided, so every parameter is missing!
        missing = t.parameters.keys
      end

      # Prompt for each missing param and save it to the paramset
      missing.each do |key|
        say
        type = t.parameters[key]['Type']
        default = options[:ask] && pkeys.include?(key) ? p.get(key) : t.parameters[key]['Default'] || ''
        description = t.parameters[key]['Description'] || false
        values = t.parameters[key]['AllowedValues'] || false
        noecho = t.parameters[key]['NoEcho'] || false

        options = {}
        options[:default] = default unless default.empty?
        options[:limited_to] = values if values
        options[:echo] = false if noecho

        say("#{description} (#{type})") if description
        answer = ''
        until answer != ''
          answer = ask(key, :cyan, options)
        end
        p.set(key, answer)
      end

      unless missing.empty?
        if yes?("Save changes to paramset?")
          unless options[:paramset]
            p.name = ask("Paramset name", :cyan, default: options[:name])
          end
          p.save!
        end
      end

      # Upload payload
      # TODO: How does the payload get passed as a parameter?
      payload_path = File.join(Dir.pwd, 'payload')
      if File.directory?(payload_path)
        payload = Hygroscope::Payload.new(payload_path)
        payload.prefix = options[:name]
        url = payload.upload!
        say_status('ok', 'Payload uploaded to:', :green)
        say_status('', url)
      end

      # TODO: Create stack
      #puts "presigned is: #{payload.generate_url}"

      # Display status of stack creation
      status
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
      status
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
      if options[:force] or yes?("Really delete stack #{options[:name]} [y/N]?")
        say("Deleting stack!")
        stack = Hygroscope::Stack.new(options[:name])
        stack.delete
        status
      end
    end

    desc 'status', 'View status of stack create/update/delete action.\nUse the --name option to change which stack is reported upon.'
    method_option :name,
      aliases: '-n',
      default: File.basename(Dir.pwd),
      desc: 'Name of stack'
    def status()
      check_path
      stack = Hygroscope::Stack.new(options[:name])

      # Query and display the status of the stack and its resources. Refresh
      # every 10 seconds until the user aborts or an error is encountered.
      begin
        s = stack.describe

        system "clear" or system "cls"

        header = {
          'Name:'    => s.stack_name,
          'Created:' => s.creation_time,
          'Status:'  => colorize_status(s.stack_status),
        }

        print_table header
        puts

        type_width   = terminal_width < 80 ? 30 : terminal_width - 50
        output_width = terminal_width < 80 ? 54 : terminal_width - 31

        puts set_color(sprintf(" %-28s %-*s %-18s ", "Resource", type_width, "Type", "Status"), :white, :on_blue)
        resources = stack.list_resources
        resources.each do |r|
          puts sprintf(" %-28s %-*s %-18s ", r[:name][0..26], type_width, r[:type][0..type_width], colorize_status(r[:status]))
        end

        if s.stack_status.downcase =~ /complete$/
          puts
          puts set_color(sprintf(" %-28s %-*s ", "Output", output_width, "Value"), :white, :on_yellow)
          s.outputs.each do |o|
            puts sprintf(" %-28s %-*s ", o.output_key, output_width, o.output_value)
          end

          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          break
        elsif s.stack_status.downcase =~ /failed$/
          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          break
        else
          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          countdown("Updating in", 9)
          puts
        end
      rescue Aws::CloudFormation::Errors::ValidationError
        fail("Stack not found")
      rescue Interrupt
        abort
      end while true
    end

    desc 'generate', "Generate and display JSON output from template files.\nTo validate that the template is well-formed use the 'validate' command."
    method_option :color,
      aliases: '-c',
      type: :boolean,
      default: true,
      desc: 'Colorize JSON output'
    def generate()
      check_path
      t = Hygroscope::Template.new(template_path)
      if options[:color]
        require 'json_color'
        puts JsonColor.colorize(t.process)
      else
        puts t.process
      end
    end

    desc 'validate', "Generate JSON from template files and validate that it is well-formed.\nThis utilzies the CloudFormation API to validate the template but does not detect logical errors."
    def validate()
      check_path
      begin
        t = Hygroscope::Template.new(template_path)
        t.validate
      rescue Aws::CloudFormation::Errors::ValidationError => e
        say_status('error', 'Validation error', :red)
        print_wrapped e.message, indent: 2
        abort
      rescue Hygroscope::TemplateYamlParseError => e
        say_status('error', 'YAML parsing error', :red)
        puts e
        abort
      rescue => e
        say_status('error', 'Unexpected error', :red)
        print_wrapped e.message, indent: 2
        abort
      else
        say_status('ok', 'Template is valid', :green)
      end
    end

    desc 'paramset', "List saved paramsets.\nIf --name is passed, shows all parameters in the named set."
    method_option :name,
      aliases: '-n',
      required: false,
      desc: 'Name of a paramset'
    def paramset()
      if options[:name]
        begin
          p = Hygroscope::ParamSet.new(options[:name])
        rescue Hygroscope::ParamSetNotFoundError
          fail("Paramset #{options[:name]} does not exist!")
        end
        say "Parameters for '#{hygro_name}' paramset '#{p.name}':", :yellow
        print_table p.paramset, indent: 2
        say "\nTo edit existing parameters, use the 'create' command with the --ask flag."
      else
        files = Dir.glob(File.join(hygro_path, 'paramsets', '*.{yml,yaml}'))
        if files.empty?
          say "No saved paramsets for '#{hygro_name}'.", :red
        else
          say "Saved paramsets for '#{hygro_name}':", :yellow
          files.map do |f|
            say "  " + File.basename(f, File.extname(f))
          end
          say "\nTo list parameters in a set, use the --name option."
        end
      end
    end
  end
end
