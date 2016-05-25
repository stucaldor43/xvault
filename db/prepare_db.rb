require_relative "../lib/dragonfly_config"
require_relative "build_schema"
require_relative "country_name_retriever"
require_relative "region"
require_relative "image_url_retriever"
require_relative "database_manager"
require_relative "../lib/s3_bucket_manager"
require "dragonfly"
require "lorem"

# implement database schema
applier = SchemaApplier.new
applier.build_schema

# insert region table records
RegionTablePreparer.new.prepare_region_table

# insert initial records for database
google_result_image_info_list = ImageUrlRetriever.new.test_fetch

dragonfly_content_hash_collection = []
valid_extensions = ["png", "gif", "jpg", "jpeg", "bmp"]
google_result_image_info_list.each do |image_item|
    original_image = Dragonfly.app.fetch_url(image_item.url)
    ratio = image_item.height / image_item.width.to_f
    thumbnail_image = Dragonfly.app.fetch_url(image_item.url).thumb("320x#{(image_item.width * ratio).to_i}")
    if (valid_extensions.index(original_image.ext))
        dragonfly_content_hash_collection << {larger_image: original_image, smaller_image: thumbnail_image}
    end
end

s3_manager = S3BucketManager.new
s3_image_hash_list = [] 
dragonfly_content_hash_collection.each do |hash|
    begin
        s3_original_image_url = s3_manager.insert_file(hash[:larger_image])
        s3_thumb_image_url = (s3_original_image_url) ?  s3_manager.insert_file(hash[:smaller_image]) : nil
        if (s3_original_image_url && s3_thumb_image_url)
            s3_image_hash_list << {original: s3_original_image_url, thumb: s3_thumb_image_url}
        end
    rescue Aws::S3::Errors::ServiceError => e
        puts e
    end
end

pg_manager = DatabaseManager.new
s3_image_hash_list.each do |img_pair|
    begin
        pg_manager.insert_images(img_pair)
    rescue => e
        puts e
    end
end

picture_primary_keys_list = pg_manager.execute_statement(
"SELECT picture_id FROM picture").column_values(0).map(&:to_i)

picture_primary_keys_list.each do |picture_record_primary_key|
    comment_count = rand(0..5)
    if comment_count > 0
      comment_count.times do |i|
        message = Lorem::Base.new(Lorem::Base::TYPES[1], rand(50..100)).output
        pg_manager.insert_comment(message, picture_record_primary_key)
      end
    end
end
