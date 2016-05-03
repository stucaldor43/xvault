require "sinatra"

set :views, "#{settings.root}/views"

get "/" do
    erb :index  
end

post "/upload" do 
   # verify user upload meets requirements
   # submit upload to s3
   # add appropriate entires to database
end


