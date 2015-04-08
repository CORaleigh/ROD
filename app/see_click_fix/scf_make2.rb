
#scf_make2.rb - tool for getting/parsing all see click fix issues from 6/25/2013 to current date

require 'net/https'
require 'hashie'
require 'rubygems'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...'
require 'date'
require 'open-uri'
require 'sqlite3'
require 'httparty'
require 'active_record'
require_relative '../../lib/scf_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'
 

DATE_FORMAT = '%m/%d/%Y'
class Maker  

 
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
  @not_maintained_response = "This location is not maintained by the City of Raleigh"
  @view_id = '6xju-znn5'   #socrata view id 
  @date = "2013-06-25T01:00:00-04:00"
  @container=[]
  @payload=[]
  @page = 179
  @pass = 4
 end

 def see_click_new #get all issues by status open, closed, acknowledged, archived
  600.times do 
    @payload.clear  
      case @pass
        when 1
          @results=HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=open&after=2013-06-25T01:00:00-04:00&page=1&per_page=1000")
        when 2
          @results=HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=closed&after=2013-06-25T01:00:00-04:00&page=1&per_page=1000")
        when 3
          @results=HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=acknowledged&after=2013-06-25T01:00:00-04:00&page=1&per_page=1000")
        when 4..604
          @results=HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=archived&after=2013-06-25T01:00:00-04:00&page=#{@page}&per_page=10")
          @page+=1
      end
    print 'page # '
    puts @page
    print 'pass # '
    puts @pass
    @pass += 1
    transform
  end
 end


  def transform #parse, rename, merge, remove objets 
    @results['issues'].each do |object|
     begin
      #rename keys
      object.rewrite( "status" => "Status",
                      "summary" => "Category",
                      "description" => "Description",
                      "rating" => "Votes",
                      "closed_at" => "Closed at",
                      "acknowledged_at" => "Acknowledged at",
                      "created_at" => "Created at",
                      "updated_at" => "Updated at",
                      "html_url" => "HTML URL",
                      "comment_url" => "Comment URL",
                      "url" => "API URL",                            
                      "id" => "Issue Id",
                      "lat" => "latitude",
                      "lng" => "longitude",
                      "address" => "Address"             
                      )
      #check comments for items that have been commented out of jurisdiction and flag (boolean)
      @comment_url = object["Comment URL"] 
      @comments = HTTParty.get("#{@comment_url}")
      @comments["comments"].each do |com|
        unless com.empty?
          if com["comment"].include? @not_maintained_response
            ooj_temp = {"OOJ Flag" =>  true}
           else
            ooj_temp = {"OOJ Flag" =>  ""}
          end
        end
        object.merge!(ooj_temp)
      end 
 
      #do time math return Days to Close, Days to Acknowledge
      start = object["Created at"]
      if !object["Acknowledged at"].nil?
        days_to_ack = DateTime.parse(object["Acknowledged at"]) - DateTime.parse(start)
        dta = {"Days to Acknowledge" => days_to_ack.to_i}
      else
        dta = {"Days to Acknowledge" => " "}       
      end
      if !object["Closed at"].nil?
        days_to_close = DateTime.parse(object["Closed at"]) - DateTime.parse(start)
        dtc = {"Days to Close" => days_to_close.to_i}
      else
        dtc = {"Days to Close" => " "}
      end
      object.merge!(dta)
      object.merge!(dtc)
      
      #add user id, image url, location
      temp_id = {"User Id " => object['reporter']['id']}
      object.merge!(temp_id)
      temp_image = { "Image URL" => object['media']['image_square_100x100']}
      object.merge!(temp_image)          
      address_temp = {'Location' => {'latitude' => object['latitude'],
                                   'longitude' => object['longitude'] }}
      object.merge!(address_temp)   
      
      #remove extranious from object
      object.except!("civic_points", "shortened_url", "point", "flag_url", "transitions", "reporter", "media")
    rescue
      next
    end
      @payload << object 
    end
    #tocsv
    export
  end

  def tocsv 
    CSV.open("seecf.csv", "wb") do |csv|
      csv << @payload.first.keys # adds the attributes name on the first line
      @payload.each do |hash|
        csv << hash.values
      end
    end
  end

  def export #push all to Socrata
   response = @client.post(@view_id, @payload)         #upload to Socrata
    puts response["Errors"].to_s + ' Errors'
    puts response["Rows Deleted"].to_s + ' Rows Deleted'
    puts response["Rows Created"].to_s + ' Rows Created'
    puts response["Rows Updated"].to_s + ' Rows Updated'
    LOGGER.info "Update complete using duncanQuery"
    LOGGER.info "................. #{response["Errors"]} Errors"
    LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
    LOGGER.info "................. #{response["Rows Created"]} Rows Created"
    LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
   end
end
Maker.new.see_click_new
