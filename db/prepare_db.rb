require_relative "../lib/dragonfly_config"
require_relative "build_schema"
require_relative "country_name_retriever"
require_relative "region"
require_relative "image_url_retriever"
require_relative "database_manager"
require_relative "../lib/s3_bucket_manager"
require "dragonfly"

# implement database schema
applier = SchemaApplier.new
applier.build_schema

# insert region table records
RegionTablePreparer.new.prepare_region_table

# insert initial records for database
google_result_image_info_list = ImageUrlRetriever.new.get_google_image_info_list

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
    s3_original_image_url = s3_manager.insert_image(hash[:larger_image])
    s3_thumb_image_url = (s3_original_image_url) ?  s3_manager.insert_image(hash[:smaller_image]) : nil
    if (s3_original_image_url && s3_thumb_image_url)
        s3_image_hash_list << {original: s3_original_image_url, thumb: s3_thumb_image_url}
    end
end

pg_manager = DatabaseManager.new
s3_image_hash_list.each do |img_pair|
    pg_manager.insert_images(img_pair)
end