require_relative "image_url_retriever"
require "pg"
require "aws-sdk"
require "digest"
require "base64"
require "dragonfly"


class DatabaseManager
   attr_accessor :region_ids, :conn
   
   def initialize
      @conn = PG::Connection.open(
            dbname: ENV["DATABASE_NAME"], 
            host: ENV["POSTGRESQL_HOST"] || ENV["IP"], 
            user: ENV["POSTGRESQL_USER"], 
            password: ENV["POSTGRESQL_PASSWORD"])
      @region_ids = conn.exec("SELECT * FROM region").column_values(0).map(&:to_i)
       
   end
   
   def insert_images(img_hash)
      if (img_hash[:original] && img_hash[:thumb])
         original_image_url = conn.escape_string(img_hash[:original])
         thumbnail_image_url = conn.escape_string(img_hash[:thumb])
         picture_table_insert_result = conn.exec("INSERT INTO picture" + 
         "(original_image_url, thumbnail_image_url ) VALUES" + 
         "(\'#{original_image_url.slice(original_image_url.index("//") + 2..original_image_url.length - 1)}\'," +
         "\'#{thumbnail_image_url.slice(thumbnail_image_url.index("//") + 2..thumbnail_image_url.length - 1)}\')")
         
         case picture_table_insert_result
         when PG::Result
            last_picture_row = conn.exec("SELECT picture_id FROM picture WHERE" +
            " original_image_url=\'#{original_image_url.slice(original_image_url.index("//") + 2..original_image_url.length - 1)}\'")
            recently_inserted_row_primary_key = last_picture_row[0]["picture_id"]
            insert_post_details(recently_inserted_row_primary_key)
         else
            raise Exception.new("Unable to insert #{original_image_url} and #{thumbnail_image_url} into picture table")
         end
         
      else
         raise Exception.new("Argument for insert_images method must contain" +
         " original and thumb keys")
      end
   end
   
   def insert_post_details(picture_rows_primary_key)
      post_detail_insert_result = conn.exec("INSERT INTO post_details" +
      "(post_date, fk_post_details_region, fk_post_details_picture)" +
      "VALUES(\'#{"#{Time.new.year}-#{Time.new.month}-#{Time.new.day}"}\', #{region_ids.sample}, #{picture_rows_primary_key})")
      
      if PG::Error === post_detail_insert_result
         raise Exception.new "Unable to insert post details for picture with id # of #{picture_rows_primary_key}"
      end
   end
   
   def close_connection
      conn.close    
   end
end