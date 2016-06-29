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
   
   def insert_images(img_hash, user_primary_key, region=nil)
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
            insert_post_details(recently_inserted_row_primary_key, user_primary_key, region)
         else
            raise Exception.new("Unable to insert #{original_image_url} and #{thumbnail_image_url} into picture table")
         end
         
      else
         raise Exception.new("Argument for insert_images method must contain" +
         " original and thumb keys")
      end
   end
   
   def insert_post_details(picture_rows_primary_key, user_primary_key, region=nil)
      if (region)
         conn.exec("INSERT INTO post_details" +
         "(post_date, fk_post_details_region, fk_post_details_picture, " +
         "fk_post_details_end_user, upvotes, downvotes, flagged) " +
         "VALUES(\'#{Time.now}\'," +
         "#{region}, #{picture_rows_primary_key}, #{user_primary_key}, " +  
         "0, 0, false);")
      else
         conn.exec("INSERT INTO post_details" +
         "(post_date, fk_post_details_region, fk_post_details_picture, " +
         "fk_post_details_end_user, upvotes, downvotes, flagged) " +
         "VALUES(\'#{Time.now}\', " +
         "NULL, #{picture_rows_primary_key}, #{user_primary_key}, 0, 0, false);")
      end
      
   end
   
   def insert_comment(message, picture_primary_key, user_primary_key)
      comment_insert_result = conn.exec("INSERT INTO comment(message, " +
      "date_created, fk_comment_picture, fk_comment_end_user, upvotes, " +
      "downvotes, flagged)" + 
      " VALUES(\'#{conn.escape_string(message)}\'," + 
      " \'#{Time.now}\', #{picture_primary_key}, #{user_primary_key} " + 
      "0, 0, false)")
      
   end
   
   def insert_character_pool_entry(url, filename)
      character_pool_insert_result = conn.exec("INSERT INTO character_pool" +
      "(s3_url, pool_name) VALUES(\'#{url}\', \'#{filename}\')")
      
   end
   
   def get_gallery_pertinent_records(page)
      offset = (page.to_i - 1) * 20
      if offset > 0
         result = conn.exec("SELECT * FROM (SELECT * FROM post_details" + 
         " INNER JOIN picture ON fk_post_details_picture=picture_id) as" +
         " T LEFT OUTER JOIN region ON fk_post_details_region=region_id" +
         " ORDER BY picture_id LIMIT 20 OFFSET #{offset}")
      else
         result = conn.exec("SELECT * FROM (SELECT * FROM post_details" + 
         " INNER JOIN picture ON fk_post_details_picture=picture_id) as" +
         " T LEFT OUTER JOIN region ON fk_post_details_region=region_id" +
         " ORDER BY picture_id LIMIT 20")   
      end
   end
   
   def get_post_details
      conn.exec("SELECT * FROM post_details")
   end
   
   def get_pictures_comments(picture_id)
      conn.exec("SELECT message, date_created FROM comment" +
      " WHERE fk_comment_picture=#{picture_id.to_i}")
   end
   
   def execute_statement(sql)
      conn.exec(sql)
   end
   
   def close_connection
      conn.close    
   end
end