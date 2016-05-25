require_relative "dragonfly_config"
require "sinatra"
require "dragonfly"
require "json"
require_relative "s3_bucket_manager"
require_relative "../db/database_manager"

set :root, File.dirname(__FILE__) + "/.."
set :views, "#{settings.root}/views"

helpers do
    def upload_size_limit
        25000 # bytes
    end
    
    def valid_image_extensions
        ["png", "gif", "jpg", "jpeg", "bmp"]
    end
    
    def valid_nonimage_extensions
        ["bin"]
    end
    
    def get_randomly_generated_name
        time_hash = Time.new.hash
        "#{rand(2 ** 8)}#{time_hash.to_s.slice(1..time_hash.to_s.length - 1)}"    
    end
    
    def create_thumbnail(dragonfly_content)
        if (valid_image_extensions.index(dragonfly_content.image_properties["format"]))
            ratio = dragonfly_content.height / dragonfly_content.width.to_f        
            thumb = Dragonfly.app.fetch_file(dragonfly_content.path).
              thumb("320x#{(dragonfly_content.width * ratio).to_i}")
            thumb.basename = get_randomly_generated_name if thumb
            thumb
        end
        
        raise Exception.new("Failed to create thumbnail") if thumb.nil?
        thumb
    end
    
    def meets_image_requirements?(dragonfly_content)
        (dragonfly_content.width <= 2048 && 
          dragonfly_content.height <= 2048 && 
            valid_image_extensions.index(dragonfly_content.image_properties["format"]))        
    end
    
    def meets_character_pool_requirements?(dragonfly_content)
        (valid_nonimage_extensions.index(dragonfly_content.image_properties["format"]) && 
          dragonfly_content.size <= upload_size_limit)
            
    end
    
    def upload_file_to_s3(dragonfly_content)
        if meets_image_requirements?(dragonfly_content)
            url = S3BucketManager.new.insert_file(dragonfly_content)
        else
            raise StandardError, "File type not allowed" +
            "(.#{dragonfly_content.image_properties["format"]} or image is too large" +
            "(#{dragonfly_content.width}x#{dragonfly_content.height})"
        end
    end
    
    def add_picture_to_database(img_urls)
        DatabaseManager.new.insert_images(img_urls)
    end
    
    def upload_file_to_site(dragonfly_content)
        if valid_image_extensions.index(dragonfly_content.image_properties["format"])
            dragonfly_content.basename = get_randomly_generated_name
            thumb = create_thumbnail(dragonfly_content)
            original_url = upload_file_to_s3(dragonfly_content)
            thumb_url = upload_file_to_s3(thumb)
            add_picture_to_database({
                original: original_url, 
                thumb: thumb_url
            })
            thumb_url
        elsif valid_nonimage_extensions.index(dragonfly_content.image_properties["format"])
         
        end
        
    end
end

get "/" do
    erb :index  
end

post "/upload" do 
   # verify user upload meets requirements
   # submit upload to s3
   # add appropriate entries to database
   begin
     original_img = Dragonfly.app.fetch_file(env["rack.input"].path)
     url = upload_file_to_site(original_img)
     JSON.generate({
         "image" => url,
         "status" => "uploaded"
     })
   rescue => e
     puts e
     puts e.backtrace
     JSON.generate({
         "status" => "failed"
     })
   end
end


