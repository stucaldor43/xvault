require "pg"

class SchemaApplier
    attr_reader :conn
    
    def initialize
        @conn = PG::Connection.open(
            dbname: ENV["DATABASE_NAME"], 
            host: ENV["POSTGRESQL_HOST"] || ENV["IP"], 
            user: ENV["POSTGRESQL_USER"], 
            password: ENV["POSTGRESQL_PASSWORD"])
    end
    def create_post_details_table
        conn.exec("CREATE TABLE post_details (
        post_details_id serial primary key,
        post_date date not null,
        fk_post_details_region int references region(region_id),
        fk_post_details_picture int references picture(picture_id) not null
        );") 
    end
    
    def create_comment_table
        conn.exec("CREATE TABLE comment (
        comment_id serial primary key,
        message text not null,
        date_created date not null,
        fk_comment_picture int references picture(picture_id) not null
        );") 
    end
    
    def create_picture_table 
        conn.exec("CREATE TABLE picture (
        picture_id serial primary key,
        original_image_url varchar(128) not null,
        thumbnail_image_url varchar(128) not null
        );") 
    end
    
    def create_region_table
        conn.exec("CREATE TABLE region (
        region_id serial primary key,
        name varchar(64) not null
        );") 
    end
    
    def create_s3_image_url_index 
        conn.exec("CREATE INDEX original_image_url ON 
        picture(original_image_url);") 
    end
    
    def create_character_pool_table
        conn.exec("CREATE TABLE character_pool (
        s3_url varchar(128) primary key not null,
        pool_name varchar(64) not null unique
        );") 
    end
    
    def close_connection
       conn.close 
    end
    
    def build_schema
        create_picture_table
        create_region_table
        create_post_details_table
        create_comment_table
        create_s3_image_url_index
        create_character_pool_table
        close_connection
    end
end

applier = SchemaApplier.new
applier.build_schema
