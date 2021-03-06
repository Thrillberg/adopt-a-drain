require 'rake'

namespace :data do
  require 'open-uri'
  require 'csv'
  require 'json'

  task download_csv: :environment do
    TYPES_TO_SKIP = ["HEADWALL", "END SECTION"]

    puts 'Downloading CSV data...'
    arcgis_path = '/ArcGIS/rest/services/PublicWorks/PublicWorks/MapServer/46/query?f=json&returnGeometry=true&outSR=4326&outFields=TASK,FORM,OPERATIONALAREA,FACILITYID,LOCATION,OWNER,STATUS,COMMENT,TYPE&where=OWNER%3D%27CITY-ROW%27%20and%20STATUS%3D%27EXISTING%27%20and%20TASK%3D%27INLET%27'
    uri = "http://gisweb2.durhamnc.gov/#{arcgis_path}&returnIdsOnly=true"
    print "uri: #{uri}\n"
    json_string = open(uri).read
    ids = JSON.parse(json_string)
    output_csv = File.open("durham_drains.csv", "w")
    output_csv.write("lon,lat,owner,watershed,type,form\n")
    ids["objectIds"].each_slice(150).each do |chunk|
      uri = "http://gisweb2.durhamnc.gov/#{arcgis_path}&objectIds=#{chunk.join(',')}"
      print "uri: #{uri}\n"
      json_string = open(uri).read
      data = JSON.parse(json_string)
      data["features"].each do |d|
        next if TYPES_TO_SKIP.include? d["attributes"]["TYPE"]
        output_csv.write("#{d["geometry"]["x"]},#{d["geometry"]["y"]},#{d["attributes"]["OWNER"]},#{d["attributes"]["OPERATIONALAREA"]},#{d["attributes"]["TYPE"]},#{d["attributes"]["FORM"]}\n")
      end
    end
    output_csv.close
  end

  task load_drains: :environment do
    puts 'Downloading Drains... ... ...'
    url = 'durham_drains.csv'
    csv_string = open(url).read
    drains = CSV.parse(csv_string, headers: true)
    puts "Downloaded #{drains.size} Drains."

    drains.each do |drain|
      thing_hash = {
        name: drain['type'],
        system_use_code: drain['type'],
        lat: drain['lat'],
        lng: drain['lon'],
      }

      thing = Thing.create(thing_hash)
    end
  end
end
