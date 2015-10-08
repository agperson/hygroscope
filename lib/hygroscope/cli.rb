require 'hygroscope'

module Hygroscope
  class Cli < Thor
    include Thor::Actions

    def initialize(*args)
      super(*args)
    end

    no_commands do
      def say_fail(message)
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

      def countdown(text, time = 5)
        print "#{text}  "
        time.downto(0) do |i|
          $stdout.write("\b")
          $stdout.write(i)
          $stdout.flush
          sleep 1
        end
      end

      def check_path
        say_fail('Hygroscope must be run from the top level of a hygroscopic directory.') unless
          File.directory?(File.join(Dir.pwd, 'template')) &&
          File.directory?(File.join(Dir.pwd, 'paramsets'))
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

      def say_paramset(name)
        begin
          p = Hygroscope::ParamSet.new(name)
        rescue Hygroscope::ParamSetNotFoundError
          say_fail("Paramset #{name} does not exist!")
        end

        say "Parameters for '#{File.basename(Dir.pwd)}' paramset '#{p.name}':", :yellow
        print_table p.parameters, indent: 2
        say "\nTo edit existing parameters, use the 'create' command with the --ask flag."
      end

      def say_paramset_list
        files = Dir.glob(File.join(hygro_path, 'paramsets', '*.{yml,yaml}'))

        say_fail("No saved paramsets for #{hygro_name}.") if files.empty?

        say "Saved paramsets for '#{hygro_name}':", :yellow
        files.map do |f|
          say '  ' + File.basename(f, File.extname(f))
        end
        say "\nTo list parameters in a set, use the --name option."
      end
    end

    # NOTE: Profiles cannot assume roles, see:
    # https://github.com/aws/aws-sdk-ruby/issues/910
    class_option :profile,
                  aliases: '-p',
                  type: :string,
                  default: 'default',
                  desc: 'AWS account credentials profile name'
    class_option :region,
                  aliases: '-r',
                  type: :string,
                  default: 'us-east-1',
                  desc: 'AWS region'

    desc 'prepare', 'Prepare to create or update a stack by generating the template, assembling parameters, and managing payload upload', hide: true
    def prepare
      # Generate the template
      t = Hygroscope::Template.new(template_path, options[:region], options[:profile])

      # If the paramset exists load it, otherwise instantiate an empty one
      p = Hygroscope::ParamSet.new(options[:paramset])

      if options[:paramset]
        # User provided a paramset, so load it and determine which parameters
        # are set and which need to be prompted.
        paramset_keys = p.parameters.keys
        template_keys = t.parameters.keys

        # Reject any keys in paramset that are not requested by template
        rejected_keys = paramset_keys - template_keys
        say_status('info', "Keys in paramset not requested by template: #{rejected_keys.join(', ')}", :blue) unless rejected_keys.empty?

        # Prompt for any key that is missing. If "ask" option was passed,
        # prompt for every key.
        missing = options[:ask] ? template_keys : template_keys - paramset_keys
      else
        # No paramset provided, so every parameter is missing!
        missing = t.parameters.keys
      end

      options[:existing].each do |existing|
        # User specified an existing stack from which to pull outputs and
        # translate into parameters. Load the existing stack.
        e = Hygroscope::Stack.new(existing, options[:region], options[:profile])
        say_status('info', "Populating parameters from #{existing} stack", :blue)

        # Fill any template parameter that matches an output from the existing
        # stack, overwriting values from the paramset object. The user will
        # be prompted to change these if they were not in the paramset or the
        # --ask option was passed.
        e.describe.outputs.each do |o|
          p.set(o.output_key, o.output_value) if t.parameters.keys.include?(o.output_key)
        end
      end if options[:existing].is_a?(Array)

      # Prompt for each missing parameter and save it in the paramset object
      missing.each do |key|
        # Do not prompt for keys prefixed with the "Hygroscope" reserved word.
        # These parameters are populated internally without user input.
        next if key =~ /^Hygroscope/

        type = t.parameters[key]['Type']
        default = p.get(key) ? p.get(key) : t.parameters[key]['Default'] || ''
        description = t.parameters[key]['Description'] || false
        values = t.parameters[key]['AllowedValues'] || false
        no_echo = t.parameters[key]['NoEcho'] || false

        # Thor conveniently provides some nice logic for formatting,
        # allowing defaults, and validating user input
        ask_opts = {}
        ask_opts[:default] = default unless default.to_s.empty?
        ask_opts[:limited_to] = values if values
        ask_opts[:echo] = false if no_echo

        puts
        say("#{description} (#{type})") if description
        # Make sure user enters a value
        # TODO: Better input validation
        answer = ''
        answer = ask(key, :cyan, ask_opts) until answer != ''

        # Save answer to paramset object
        p.set(key, answer)

        # Add a line break
        say if no_echo
      end

      # Offer to save paramset if it was modified
      # Filter out keys beginning with "Hygroscope" since they are not visible
      # to the user and may be modified on each invocation.
      unless missing.reject { |k| k =~ /^Hygroscope/ }.empty?
        puts
        if yes?('Save changes to paramset?')
          unless options[:paramset]
            p.name = ask('Paramset name', :cyan, default: options[:name])
          end
          p.save!
        end
      end

      # Upload payload
      payload_path = File.join(Dir.pwd, 'payload')
      if File.directory?(payload_path)
        payload = Hygroscope::Payload.new(payload_path, options[:region], options[:profile])
        payload.prefix = options[:name]
        payload.upload!
        p.set('HygroscopePayloadBucket', payload.bucket) if missing.include?('HygroscopePayloadBucket')
        p.set('HygroscopePayloadKey', payload.key) if missing.include?('HygroscopePayloadKey')
        p.set('HygroscopePayloadSignedUrl', payload.generate_url) if missing.include?('HygroscopePayloadSignedUrl')
        say_status('ok', 'Payload uploaded to:', :green)
        say_status('', "s3://#{payload.bucket}/#{payload.key}")
      end

      [t, p]
    end

    desc 'create', "Create a new stack.\nUse the --name option to launch more than one stack from the same template.\nCommand prompts for parameters unless --paramset is specified.\nUse --existing to set parameters from an existing stack's outputs."
    method_option :name,
                  aliases: '-n',
                  default: File.basename(Dir.pwd),
                  desc: 'Name of stack'
    method_option :paramset,
                  aliases: '-s',
                  required: false,
                  desc: 'Name of saved paramset to use (optional)'
    method_option :existing,
                  aliases: '-e',
                  type: :array,
                  required: false,
                  desc: 'Name of one or more existing stacks from which to retrieve outputs as parameters (optional)'
    method_option :ask,
                  aliases: '-a',
                  type: :boolean,
                  default: false,
                  desc: 'Still prompt for parameters even when using a paramset'
    method_option :tags,
                  aliases: '-t',
                  type: :array,
                  required: false,
                  default: [],
                  desc: 'One or more parameters to apply as tags to all stack resources'
    def create
      check_path
      validate

      # Prepare task takes care of shared logic between "create" and "update"
      template, paramset = prepare

      stack = Hygroscope::Stack.new(options[:name], options[:region], options[:profile])
      stack.parameters = paramset.parameters
      stack.template = template.compress

      stack.tags['X-Hygroscope-Template'] = hygro_name
      options[:tags].each do |tag|
        if paramset.get(tag)
          stack.tags[tag] = paramset.get(tag)
        else
          say_status('info', "Skipping tag #{tag} because it does not exist", :blue)
        end
      end

      stack.capabilities = ['CAPABILITY_IAM']
      stack.timeout = 60

      stack.create!

      status
    end

    desc 'update', "Update a running stack.\nCommand prompts for parameters unless a --paramset is specified."
    method_option :name,
                  aliases: '-n',
                  default: File.basename(Dir.pwd),
                  desc: 'Name of stack'
    method_option :paramset,
                  aliases: '-s',
                  required: false,
                  desc: 'Name of saved paramset to use (optional)'
    method_option :ask,
                  aliases: '-a',
                  type: :boolean,
                  default: false,
                  desc: 'Still prompt for parameters even when using a paramset'
    def update
      # TODO: Right now update just does the same thing as create, not taking
      # into account the complications of updating (which params to keep,
      # whether to re-upload the payload, etc.)
      check_path
      validate

      # Prepare task takes care of shared logic between "create" and "update"
      template, paramset = prepare

      s = Hygroscope::Stack.new(options[:name], options[:region], options[:profile])
      s.parameters = paramset.parameters
      s.template = template.compress
      s.capabilities = ['CAPABILITY_IAM']
      s.timeout = 60
      s.update!

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
    def delete
      check_path
      abort unless options[:force] ||
                   yes?("Really delete stack #{options[:name]} [y/N]?")

      say('Deleting stack!')
      stack = Hygroscope::Stack.new(options[:name], options[:region], options[:profile])
      stack.delete!
      status
    end

    desc 'status', 'View status of stack create/update/delete action.\nUse the --name option to change which stack is reported upon.'
    method_option :name,
                  aliases: '-n',
                  default: File.basename(Dir.pwd),
                  desc: 'Name of stack'
    def status
      check_path
      stack = Hygroscope::Stack.new(options[:name], options[:region], options[:profile])

      # Query and display the status of the stack and its resources. Refresh
      # every 10 seconds until the user aborts or an error is encountered.
      begin
        s = stack.describe

        system('clear') || system('cls')

        header = {
          'Name:'    => s.stack_name,
          'Created:' => s.creation_time,
          'Status:'  => colorize_status(s.stack_status)
        }

        print_table header
        puts

        # Fancy acrobatics to fit output to terminal width. If the terminal
        # window is too small, fallback to something appropriate for ~80 chars
        term_width = `stty size 2>/dev/null`.split[1].to_i || `tput cols 2>/dev/null`.to_i
        type_width   = term_width < 80 ? 30 : term_width - 50
        output_width = term_width < 80 ? 54 : term_width - 31

        # Header row
        puts set_color(sprintf(' %-28s %-*s %-18s ', 'Resource', type_width, 'Type', 'Status'), :white, :on_blue)
        resources = stack.list_resources
        resources.each do |r|
          puts sprintf(' %-28s %-*s %-18s ', r[:name][0..26], type_width, r[:type][0..type_width], colorize_status(r[:status]))
        end

        if s.stack_status.downcase =~ /complete$/
          # If the stack is complete display any available outputs and stop refreshing
          puts
          puts set_color(sprintf(' %-28s %-*s ', 'Output', output_width, 'Value'), :white, :on_yellow)
          s.outputs.each do |o|
            puts sprintf(' %-28s %-*s ', o.output_key, output_width, o.output_value)
          end

          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          break
        elsif s.stack_status.downcase =~ /failed$/
          # If the stack failed to create, stop refreshing
          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          break
        else
          puts "\nMore information: https://console.aws.amazon.com/cloudformation/home"
          countdown('Updating in', 9)
          puts
        end
      rescue Aws::CloudFormation::Errors::ValidationError
        say_fail('Stack not found')
      rescue Interrupt
        abort
      end while true
    end

    desc 'generate',
         "Generate and display JSON output from template files.\n" \
         "To validate that the template is well-formed use the 'validate' command."
    method_option :color,
                  aliases: '-c',
                  type: :boolean,
                  default: true,
                  desc: 'Colorize JSON output'
    def generate
      check_path
      t = Hygroscope::Template.new(template_path, options[:region], options[:profile])
      if options[:color]
        require 'json_color'
        puts JsonColor.colorize(t.process)
      else
        puts t.process
      end
    end

    desc 'validate', "Generate JSON from template files and validate that it is well-formed.\nThis utilzies the CloudFormation API to validate the template but does not detect logical errors."
    def validate
      check_path

      begin
        t = Hygroscope::Template.new(template_path, options[:region], options[:profile])
        t.validate
      rescue Aws::CloudFormation::Errors::ValidationError => e
        say_fail("Validation error: #{e.message}")
      rescue Hygroscope::TemplateYamlParseError => e
        say_fail("YAML parsing error: #{e.message}")
      rescue => e
        say_fail(e.message)
      else
        say_status('ok', 'Template is valid', :green)
      end
    end

    desc 'paramset', "List saved paramsets.\nIf --name is passed, shows all parameters in the named set."
    method_option :name,
                  aliases: '-n',
                  required: false,
                  desc: 'Name of a paramset'
    def paramset
      if options[:name]
        say_paramset(options[:name])
      else
        say_paramset_list
      end
    end
  end
end
