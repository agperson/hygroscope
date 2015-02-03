require 'hygroscope'

module Hygroscope
  class Stack
    attr_accessor :name, :tags, :parameters
    attr_writer :template, :capabilities, :on_failure, :timeout
    attr_reader :client

    def initialize(name)
      @name = name
      @parameters = {}
      @tags = {}
      @template = ''
      @capabilities = []
      @timeout = 15
      @on_failure = 'DO_NOTHING'
      @client = Aws::CloudFormation::Client.new
    end

    def create!
      stack_parameters = []
      @parameters.each do |k, v|
        stack_parameters << {
          parameter_key: k,
          parameter_value: v.to_s
        }
      end

      stack_tags = []
      @tags.each do |k, v|
        stack_tags << {
          key: k,
          value: v.to_s
        }
      end

      stack_opts = {
        stack_name: @name,
        template_body: @template,
        parameters: stack_parameters,
        timeout_in_minutes: @timeout,
        on_failure: @on_failure
      }

      stack_opts['capabilities'] = @capabilities unless @capabilities.empty?
      stack_opts['tags'] = stack_tags

      begin
        stack_id = @client.create_stack(stack_opts)
      rescue => e
        raise e
      end

      stack_id
    end

    def update!
      stack_parameters = []
      @parameters.each do |k, v|
        stack_parameters << {
          parameter_key: k,
          parameter_value: v.to_s
        }
      end

      stack_opts = {
        stack_name: @name,
        template_body: @template,
        parameters: stack_parameters
      }

      stack_opts['capabilities'] = @capabilities unless @capabilities.empty?

      begin
        stack_id = @client.update_stack(stack_opts)
      rescue => e
        raise e
      end

      stack_id
    end

    def delete!
      @client.delete_stack(stack_name: @name)
    rescue => e
      raise e
    end

    def describe
      resp = @client.describe_stacks(stack_name: @name)
    rescue => e
      raise e
    else
      resp.stacks.first
    end

    def list_resources
      resp = @client.describe_stack_resources(stack_name: @name)
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
