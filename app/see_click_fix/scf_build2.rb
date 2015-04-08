
#scf_build2.rb - tool for updating see click fix data and pushing to Socrata portal
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
   
  #@view_id = 'ckqf-irpp'   #socrata view id - working set
  @view_id =  "q2m6-qdsj"           #socrata view id - published set
  @date = Date.today - 45  #set to get all issues from last 30 days
  @payload=[]
 end

 def see_click_new #get all issues by status open, closed, acknowledged, archived

  @results=HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&after=#{@date}&page=1&per_page=1000")
  transform
end

  def transform #parse, rename, merge, remove objets 
    @results['issues'].each do |object|
      temp_id = {:user_id => object['reporter']['id']}
      object.merge!(temp_id)
      temp_image = { :image => object['media']['image_square_100x100']}
      object.merge!(temp_image)
      object.rewrite('url' => 'api_url', 'id' => 'issue_id', 'lat' => 'latitude', 'lng' => 'longitude')            
      address_temp = {'location' => {'latitude' => object['latitude'],
                                   'longitude' => object['longitude'] }}
      object.merge!(address_temp)   
      object.except!("civic_points", "shortened_url", "point", "flag_url", "transitions", "reporter", "media")
      print '.'
      @payload << object 
    end
    print "\n"
    export
  end

  def export #push all to Socrata
   response = @client.post(@view_id, @payload)         #upload to Socrata
    puts response["Errors"].to_s + ' Errors'
    puts response["Rows Deleted"].to_s + ' Rows Deleted'
    puts response["Rows Created"].to_s + ' Rows Created'
    puts response["Rows Updated"].to_s + ' Rows Updated'
    LOGGER.info "Update complete using scf_build2"
    LOGGER.info "................. #{response["Errors"]} Errors"
    LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
    LOGGER.info "................. #{response["Rows Created"]} Rows Created"
    LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
   end
end
Maker.new.see_click_new
