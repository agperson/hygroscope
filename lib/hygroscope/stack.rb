require 'hygroscope'

module Hygroscope
  class Stack
    attr_accessor :name
    attr_reader :client

    def initialize(name)
      @name = name
      @client = Aws::CloudFormation::Client.new
    end

    def delete
      begin
        @client.delete_stack(stack_name: @name)
      rescue => e
        raise e
      end
    end

    def describe
      begin
        resp = @client.describe_stacks(stack_name: @name)
      rescue => e
        raise e
      else
        resp.stacks.first
      end
    end

    def list_resources
      begin
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
end
