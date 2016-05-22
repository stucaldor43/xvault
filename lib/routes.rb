require "sinatra"
require "dragonfly"
require_relative "s3_bucket_manager"
require_relative "database_manager"

set :root, File.dirname(__FILE__) + "/.."
set :views, "#{settings.root}/views"

helpers do
    def upload_size_limit
        25000 # bytes
    end
    
    def valid_image_extensions
        valid_extensions = ["png", "gif", "jpg", "jpeg", "bmp"]
    end
    
    def get_randomly_generated_name
        time_hash = Time.new.hash
        "#{rand(2 ** 8)}#{time_hash.to_s.slice(1..time_hash.to_s.length - 1)}"    
    end
    
    def create_thumbnail(dragonfly_content)
        if (valid_extensions.index(dragonfly_content.ext))
            ratio = dragonfly_content.height / dragonfly_content.width.to_f        
            thumb = dragonfly.app.fetch_file(dragonfly_content.file).
              thumb("320x#{(image_item.width * ratio).to_i}")
            thumb.basename = get_randomly_generated_name if thumb
        end
        
        raise Exception.new("Failed to create thumbnail") if thumb.nil?
        thumb
    end
    
    def meets_image_requirements?(dragonfly_content)
        (dragonfly_content.width <= 2048 && 
          dragonfly_content.height <= 2048 && 
            valid_image_extensions.index(dragonfly_content.ext))        
    end
    
    def meets_character_pool_requirements?(dragonfly_content)
        (dragonfly_content.ext == "bin" && 
          dragonfly_content.size <= upload_size_limit)
            
    end
    
    def upload_file_to_s3(dragonfly_content)
        S3BucketManager.new.insert_file(dragonfly_content)
    end
    
    def add_picture_to_database(img_urls)
        DatabaseManager.new.insert_images(img_urls)
    end
end

get "/" do
    erb :index  
end

put "/upload" do 
   # verify user upload meets requirements
   # submit upload to s3
   # add appropriate entries to database
end


