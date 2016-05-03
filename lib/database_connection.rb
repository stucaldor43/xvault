require "pg"

class DatabaseConnection
   attr_reader :conn
   
   def initialize
      @conn = PG::Connection.open(dbname: ENV["DATABASE_NAME"], host: ENV["POSTGRESQL_HOST"] || ENV["IP"], 
      user: ENV["POSTGRESQL_USER"], password: ENV["POSTGRESQL_PASSWORD"]  ) 
   end
   
   def close
      conn.close 
   end
   
   def result(query)
       conn.exec(query)
   end
end

connection = DatabaseConnection.new

