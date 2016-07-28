require 'aws-sdk'
require 'digest'
require 'base64'
require 'dragonfly'

class S3BucketManager
    attr_accessor :aws_container

    def initialize
        initialize_aws_container
    end

    def initialize_aws_container
        client = Aws::S3::Client.new(
            region: 'us-west-2',
            access_key_id: ENV['AWS_ACCESS_KEY_ID'],
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
        resource = Aws::S3::Resource.new(client: client)
        containers = resource.buckets
        @aws_container = containers
                         .find { |pail| pail.name == ENV['S3_BUCKET_NAME'] }
    end

    def insert_file(dragonfly_content)
        time_hash = Time.new.hash
        s3_obj = aws_container.put_object(
            acl: 'public-read',
            body: dragonfly_content.file,
            content_length: dragonfly_content.size,
            content_md5: dragonfly_content.file do |f|
                Digest::MD5.base64digest(f.read)
            end,
            content_type: dragonfly_content.mime_type,
            key: dragonfly_content.basename + time_hash.to_s
                 .slice(1..time_hash.to_s.length - 1)
        )
        s3_obj.public_url
    end
end
