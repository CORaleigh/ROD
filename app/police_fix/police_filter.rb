#collection of methods filters for police data set to bring into compliance with police policies
#this is a loose collection and is not intended to run as a single script

require 'net/https'
require 'hashie'
require 'rubygems'
require 'csv'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require_relative '../../lib/scf_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'    

class FixPolice

  def initialize 
    @client = SODA::Client.new({
     :domain => 'data.raleighnc.gov',
     :app_token => configatron.app_token,
     :username => configatron.client_username,
     :password => configatron.client_pass,
     :content_type => 'text/plain',
     :mime_type => 'JSON',
     :ignore_ssl => true
      })
    @payload=[]
    @sliced_payload = []
    @view_id = 'ujty-3kam'  
    @counter = 0
    @counter_2 = 0
    @csv_name = 'csv_output_name.csv' # change this to the desired output name for your csv
    http = Net::HTTP.new(@host, @port) #fix timeout issues
    http.read_timeout = 500
    
  def process #switch for running parts of script
     #beat_to_district  #convert beat to districts using beat_lookup
     #filters           #filter on (@filter) strings to remove geo from police dataset
     #to_csv            #convert hash to csv and write to a file
     #split_csv_coords  #split geo coordinates into lat and lon columns
     join_csv_coords
     #load_csv          #load a csv file and convert to hash
     #load_psv          #load a psv (pipe seperted value) and convert to hash
     #purge             #load a csv file, convert to array of hashs, add '{":deleted" => true}' to each hash and export to socrata !caution this is a destructive method.
     #replace           #load a csv file, convert to array of hashes and post to Socrata. This will not cause any duplications.

  end

   # police LCR DESC strings to filter on  
  @filter = ["sex", "sex offense/incest", "sex offense/all other", "sex offense/all other sex offenses", "human trafficking/commercial sex acts",
   "sex offense/assault with an object", "sex offense/forcible fondling", "sex offense/forcible rape", "sex offense/forcible sodomy",
   "sex offense/fornication","sex offense/incest", "sex offense/indecent liberities with minor", "sex offense/sodomy, crime against nature", 
   "sex offense/statutory rape", "statutory rape/juvenile", "juvenile/truancy", "juvenile/runaways (under 18)", "juvenils/suspicion",
   "juvenile/runaway", "juvenile/curfews & loitering (under 18)", "juvenile/child abuse or neglect", "indecent liberties w/minor/juvenile", 
   "indecent exposure/juvenile", "disorderly conduct/all other/juvenile", "child/offenses against family - all other", "child obscenity violations", 
   "child neglect", "child abuse/simple", "child abuse/aggravated", "child abuse","misc/deceased person", "miscellaneous/deceased person", 
   "misc/citizen request-traffic", "miscellaneous/mental commitment", "miscellaneous/missing person (15-under)", "miscellaneous/missing person (16-over)", 
   "miscellaneous/overdose", "misc/id theft (other jurisdiction)", "misc/lost or stolen property", "misc/mental commitment", 
   "misc/missing person / 15 yrs. and younger", "misc/missing person / age 16 and older", "misc/suicide", "misc/suicide/attempted", 
   "miscellaneous/suicide","miscellaneous/injured person","misc/injured person", "misc/request for service", "misc/talk with officer", 
   "family offenses/nonviolent", "miscellaneous/overdose death", "engaging in affray/juvenile", "juvenile/suspicion", "rape by force", 
   "rape/attempted", "traffic/citizen request"                             
   ]
  end

  def beat_lookup(filter)  #beat to district conversion lookup 
    case filter["BEAT"].to_i
    when 100..199, 2100..2199
      temp_dist = {"DISTRICT" => "NORTHWEST"}
    when 200..299, 2200..2299
      temp_dist = {"DISTRICT" => "NORTH"}
    when 300..399, 2300..2399
      temp_dist = {"DISTRICT" => "NORTHEAST"}
    when 400..499, 2400..2499
      temp_dist = {"DISTRICT" => "SOUTHEAST"} 
    when 500..599, 2500..2599
      temp_dist = {"DISTRICT" => "DOWNTOWN"} 
    when 600..699, 2600..2699
      temp_dist = {"DISTRICT" => "SOUTWEST"}  
    else 
      temp_dist = {"DISTRICT" => ""} 
    end
    filter.merge!(temp_dist)   
  end

  def beat_to_district #read police data from csv, returns a hash containing INC NO and DISTRICT based on BEAT, exports to Socrata.
                       #uses Beat to District conversion lookup

    csv_data = CSV.read("Police_Master.csv", "r") #use for | seperated values  , col_sep: '|'
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @raw_data.each do |filter|
      beat_lookup(filter)
      nfil = {"INC NO" => filter["INC NO"], "DISTRICT" => filter["DISTRICT"]}
      @payload <<  nfil    
      @counter +=1  
    end
    #puts @payload
    puts @counter
    export
  end

  def filter #
    csv_data = CSV.read("Daily_Police_Incidents.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @raw_data.each do |filter|
      @counter_2 +=1
      if (@filter.include?(filter["LCR DESC"].downcase)) &&  (!filter["LOCATION"].to_s.empty?) #reduce payload to update rows without empty location field
        filter["LOCATION"] = " "           
        @payload << filter 
        print "."
        @counter +=1  
      end
    end
    puts
    puts "total"
    puts @counter_2
    puts "filtered"
    puts @counter
     
    export
  end

  def split_csv_coords # split police coordinates into lat & lng columns and writes to csv
    temp_loc = {}
    package = []
    csv_data = CSV.read("Police_jun29.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @raw_data.each do |filter|
      
      if filter["LOCATION"] != " "
         (@lat,@lon)=filter["LOCATION"].gsub(/[()]/,'').split(',')
         temp_loc = {"lat" => @lat, "lng" => @lon}
      else 
        temp_loc = {"lat" => "", "lng" => ""}
      end

      filter.merge!(temp_loc)
      filter.delete("LOCATION")
      package << filter

    end
     to_csv(package)
  end

  def join_csv_coords #join long and lat, strip out all other fields and post back to Socrata - updated coords move lat & long to
                      #a point on the street center line
    @package = []
    @csv_name = "police_data_moved2.csv" #edited csv file with coords moved to street centerline
      load_csv(@csv_name)
      @raw_data.delete_if { |h| h["NEAR_Y"].to_i <= 1}  #remove hash if coordinates are < 1
      @raw_data.each_with_index do |join, index|
        joined_coords = '(' + join["NEAR_Y"].to_s + ',' + join["NEAR_X"].to_s + ')'
        temp_location = {"LOCATION" => joined_coords}
        join.merge!(temp_location)
        join.rewrite("INC_NO" => "INC NO")
        join.delete("OBJECTID")
        join.delete("LCR")
        join.delete("LCR_DESC")
        join.delete("INC_DATETIME")
        join.delete("DISTRICT")
        join.delete("lat")
        join.delete("lng")
        join.delete("NEAR_FID")
        join.delete("NEAR_DIST")
        join.delete("NEAR_X")
        join.delete("NEAR_Y")
        join.delete("NEAR_ANGLE")
        @package << join
        print '.'
     end   
     export(@package)
  end

  def to_csv(h_data) #hash to csv
    @package=h_data
    CSV.open("news.csv", "wb") do |csv|
      csv << @package.first.keys # adds the attributes name on the first line
      @package.each do |hash|
        csv << hash.values
      end
    end
  end

  def load_csv(csv_name) #comma seperated value to hash
    csv_data = CSV.read("#{csv_name}", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    #to_csv(@raw_data) 
  end

  def load_psv #pipe seperated value to hash
    csv_data = CSV.read("#{@csv_name}", "r", col_sep: '|')
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    #to_csv(@raw_data)
  end
  
  def purge #remove all 2013 police data 
    @payload =[]               
    csv_data = CSV.read("p2013.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @payload = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @payload.each do |remove|
      addon = {":deleted" =>  true}  #all rows with a unique identifier and a {":deleted" => true } hash will be deleted from socrata
      remove.merge!(addon)
    end
    puts 'purging police records....'
    export(@payload)
  end

  def replace #repost all police 2013 data
    @payload = []
    csv_data = CSV.read("p2013.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @payload = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    puts 'pushing police records....'
    export(@payload)
  end

  def export(set)  #  send to Socrata

      response = @client.post(@view_id, set)         #upload to Socrata & log response
      puts
      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'

   end
end

FixPolice.new.process
