class CountryNameRetriever
    def retrieve_names
        File.open("#{File
        .dirname(__FILE__)}/../country_info/lat_long.txt", 'r') do |f|
            lines = f.readlines("\n")
            lines.map do |line|
                line.split(',')[0]
            end
        end
    end
end
