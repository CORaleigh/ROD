#Filter for police data set to bring into compliance with police policies
#Requires csv file in this folder

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
    @view_id = 'guyh-emm5'  
    @counter = 0
    @counter_2 = 0
    http = Net::HTTP.new(@host, @port) #fix timeout issues
    http.read_timeout = 500
         
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
  
  def process #switch for uploading entire set or just uploading filtered data (smaller sub set)
    #bulk_filter
    sub_filter
    #readd
  end

  def readd

    csv_data = CSV.read("Police_Master.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    
    @raw_data.each do |filter|
       
      if (@filter.include?(filter["LCR DESC"].downcase)) 
        @payload << filter 
        print "."
        @counter +=1  
        puts @counter
      end
    end
export

 
  end
  def sub_filter #push only filtered objects
    csv_data = CSV.read("Daily_Police_Incidents.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @raw_data.each do |filter|
      @counter_2 +=1
      if (@filter.include?(filter["LCR DESC"].downcase)) &&  (!filter["LOCATION"].to_s.empty?) #reduce payload to update rows without empty location field
        filter["LOCATION"] = " "           
        #filter["BEAT"] = " "
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

  def bulk_filter #process entire set and push 
    csv_data = CSV.read("Police_Incident_Data.csv", "r")
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @raw_data = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @raw_data.each do |filter|
      @counter_2 +=1
      if @filter.include?(filter["LCR DESC"].downcase)
        filter["LOCATION"] = " "
        @counter +=1     
      end
        filter["BEAT"] = " "
        @payload << filter 
        print "."
    end
    puts
    puts "total"
    puts @counter_2
    puts "filtered"
    puts @counter
    chunk
    #export
  end

  def chunk #chunk into managable parts for easier upload
    @payload.each_slice(100) do |slice|
      @sliced_payload << slice
      export
      sleep(30.seconds)#try to keep Socrata from choking
    end
  end

  def export  #  send to Socrata
      #response = @client.post(@view_id, @sliced_payload)    #upload to socrata in chunks
      response = @client.post(@view_id, @payload)         #upload to Socrata & log response
      puts
      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'

   end
end

FixPolice.new.process
