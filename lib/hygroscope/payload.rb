require 'hygroscope'
require 'archive/zip'

module Hygroscope
  class Payload
    attr_writer :prefix
    attr_reader :path, :bucket, :archive, :key

    def initialize(path, region, profile)
      @path = path
      @region = region
      @profile = profile
      @credentials = Aws::SharedCredentials.new(profile_name: @profile)

      # TODO: This will fail if using root creds or lacking GetUser priv,
      # neither of which should be the case when using hygroscope -- but
      # we should check and error before getting to this point.
      @account_id = Aws::IAM::Client.new(region: @region, credentials: @credentials).get_user.user.arn.split(':')[4]
      @region = ENV['AWS_REGION'] || 'us-east-1'
      @bucket = "hygroscope-payloads-#{@account_id}-#{@region}"
      @name = "payload-#{Time.new.to_i}.zip"

      @client = Aws::S3::Client.new(region: @region, credentials: @credentials)
    end

    def prefix
      @prefix || File.dirname(File.dirname(@path))
    end

    def key
      "#{@prefix}/#{@name}"
    end

    def create_bucket
      # Returns success if bucket already exists
      @client.create_bucket(bucket: @bucket, acl: 'private')
    end

    def prepare
      archive_path = File.join(Dir.tmpdir, @name)
      Archive::Zip.archive(archive_path, "#{@path}/.")

      @archive = File.open(archive_path)
      at_exit { File.unlink(@archive) }
    end

    def send
      @client.put_object(
        bucket: @bucket,
        key: key,
        body: @archive
      )
    end

    def upload!
      create_bucket
      prepare
      send

      "s3://#{@bucket}/#{key}"
    end

    def generate_url(_timeout = 3600)
      signer = Aws::S3::Presigner.new(client: @client)
      signer.presigned_url(:get_object, bucket: @bucket, key: key)
    end
  end
end
