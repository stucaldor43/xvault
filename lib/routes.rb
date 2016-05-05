require "sinatra"

set :root, File.dirname(__FILE__) + "/.."
set :views, "#{settings.root}/views"

get "/" do
    erb :index  
end

post "/upload" do 
   # verify user upload meets requirements
   # submit upload to s3
   # add appropriate entries to database
end


