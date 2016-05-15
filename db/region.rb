require "pg"
require_relative "country_name_retriever"

class RegionTablePreparer
    attr_reader :conn
    
    def initialize
        @conn = PG::Connection.open(
            dbname: ENV["DATABASE_NAME"], 
            host: ENV["POSTGRESQL_HOST"] || ENV["IP"], 
            user: ENV["POSTGRESQL_USER"], 
            password: ENV["POSTGRESQL_PASSWORD"])
    end
    
    def insert_regions
        region_names = CountryNameRetriever.new.retrieve_names
        region_names.each do |name|
           conn.exec("BEGIN;INSERT INTO region(name) VALUES ('#{name}');COMMIT;") 
        end
    end
    
    def close_connection
        conn.close    
    end
    
    def prepare_region_table
       insert_regions
       close_connection
    end
end

