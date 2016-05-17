require "json"
require "uri"
require "net/http"
require "dragonfly"

class ImageUrlRetriever
   attr_reader :search_terms, :url_sans_parameters, :googlehost, :img_type,
   :img_size, :search_type
   
   def initialize
    @search_terms =  ["xcom2+enemies", "xcom2+sharpshooter","xcom2+grenadier",
    "xcom2+specialist", "xcom2+ranger", "xcom2+psi+operative"]
    @url_sans_parameters = "https://www.googleapis.com/customsearch/v1?"
    @googlehost = "google.com"
    @img_type = "photo"
    @img_size = "xxlarge"
    @search_type = "image"
   end
   
   ImgInfo = Struct.new(:url, :width, :height)
   def get_google_image_info_list
    image_info_list = []
    search_terms.each do |term|
        start = 1
        5.times do |iteration|
          res = get_response "#{url_sans_parameters}q=#{term}&cx=#{ENV["SEARCH_ENGINE_CX"]}&key=#{ENV["GOOGLE_BROWSER_API_KEY"]}&googlehost=#{googlehost}&imgType=#{img_type}&imgSize=#{img_size}&searchType=#{search_type}&start=#{start}" 
          
          if (Net::HTTPSuccess === res)
              response_hash = JSON.parse("#{res.body}")
              response_hash["items"].each do |search_item|
                if search_item["image"]["width"] && search_item["image"]["width"] >= 1024
                  image_info_list << ImgInfo.new(search_item["link"], search_item["image"]["width"], search_item["image"]["height"] )
                end    
              end
              
              break if response_hash["queries"]["nextPage"].length <= 0
              start = response_hash["queries"]["nextPage"].first["startIndex"]
          end
        end
    end
    image_info_list
   end
   
   
   def test_fetch
      start = 1
      res = get_response "#{url_sans_parameters}q=#{search_terms.first}&cx=#{ENV["SEARCH_ENGINE_CX"]}&key=#{ENV["GOOGLE_BROWSER_API_KEY"]}&googlehost=#{googlehost}&imgType=#{img_type}&imgSize=#{img_size}&searchType=#{search_type}&start=#{start}" 
      response_hash = JSON.parse("#{res.body}")
      image_info_list = []
      response_hash["items"].each do |search_item|
        if search_item["image"]["width"] && search_item["image"]["width"] >= 600
            image_info_list << ImgInfo.new(search_item["link"], search_item["image"]["width"], search_item["image"]["height"] ) 
        end
      end
      image_info_list
   end
   
   def get_response(url)
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
   end
end