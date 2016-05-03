class CountryNameRetriever
    
    def retrieve_names 
        File.open("#{Dir.pwd}/../country_info/lat_long.txt", "r") do |f|
           lines = f.readlines("\n")
           names = lines.map do |line|
               line.split(",")[0]
           end
        end
    end
end

