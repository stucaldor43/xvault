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
        post_date timestamp not null,
        fk_post_details_region int references region(region_id),
        fk_post_details_picture int references picture(picture_id) not null,
        fk_post_details_end_user int references end_user(user_id) not null,
        upvotes int not null,
        downvotes int not null,
        flagged boolean not null
        );") 
    end
    
    def create_comment_table
        conn.exec("CREATE TABLE comment (
        comment_id serial primary key,
        message text not null,
        date_created timestamp not null,
        fk_comment_picture int references picture(picture_id) not null,
        fk_comment_end_user int references end_user(user_id) not null,
        upvotes int not null,
        downvotes int not null,
        flagged boolean not null
        );") 
    end
    
    def create_picture_table 
        conn.exec("CREATE TABLE picture (
        picture_id serial primary key,
        original_image_url varchar(64) not null,
        thumbnail_image_url varchar(64) not null
        );") 
    end
    
    def create_region_table
        conn.exec("CREATE TABLE region (
        region_id serial primary key,
        name varchar(64) not null
        );") 
    end
    
    def create_end_user_table
       conn.exec("CREATE TABLE end_user (
        user_id serial primary key,
        username varchar(32) not null unique,
        account_password varchar(32) not null,
        role user_role not null, 
        last_upvote_time timestamp,
        last_downvote_time timestamp
        );") 
    end
    
    def create_s3_image_url_index 
        conn.exec("CREATE INDEX original_image_url ON 
        picture(original_image_url);") 
    end
    
    def create_user_role_enum
        conn.exec("CREATE TYPE user_role AS ENUM (\'member\', \'admin\');") 
    end
    
    def close_connection
       conn.close 
    end
    
    def build_schema
        create_user_role_enum
        create_picture_table
        create_region_table
        create_end_user_table
        create_post_details_table
        create_comment_table
        create_s3_image_url_index
        close_connection
    end
end


