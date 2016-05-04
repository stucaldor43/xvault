require "pg"

class TableDropper
   attr_reader :conn
   
   def initialize
        @conn = PG::Connection.open(
            dbname: ENV["DATABASE_NAME"], 
            host: ENV["POSTGRESQL_HOST"] || ENV["IP"], 
            user: ENV["POSTGRESQL_USER"], 
            password: ENV["POSTGRESQL_PASSWORD"])
   end
   
   def drop
       drop_comment_table
       drop_region_table
       drop_picture_table
       drop_post_details_table
       
   end
   
   def drop_comment_table
       conn.exec("DROP TABLE comment;")
   end
   
   def drop_picture_table
       conn.exec("DROP TABLE picture CASCADE;")
   end
   
   def drop_post_details_table
       conn.exec("DROP TABLE post_details CASCADE;")
   end
   
   def drop_region_table
       conn.exec("DROP TABLE region CASCADE;")
   end
end

TableDropper.new.drop