#duncanQuery.rb

require 'net/https'
require 'hashie'
require 'rubygems'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...'
require 'date'
require 'active_record'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require_relative '../../lib/parking_logger.rb'
require_relative '../../lib/defaults.rb'
 


DB=ActiveRecord::Base.establish_connection(
 :adapter  => 'sqlite3',
 :database => '../../db/parking.db'
)
 
class Space < ActiveRecord::Base
  
  def initialize(db) 
    @client = SODA::Client.new({
   :domain => 'data.raleighnc.gov',
   :app_token => configatron.app_token,
   :username => configatron.client_username,
   :password => configatron.client_pass,
   :content_type => 'text/plain',
   :mime_type => 'JSON',
   :ignore_ssl => true 
   })  
   @view_id = '6rkq-2hft'  
   @db=db
   @count=0
   @unreported_count = 0
   @zone=1
   @update_time = DateTime.now.strftime("%A, %b %d   %I:%M%p")
   @date_today = Date.today.strftime("%A, %b %d")
   @unarray =[]
  end

  def query
    LOGGER.info "--------------------------------------------------"  
    LOGGER.info "update started"
    while @zone <= 7 do  #query each zone for updates
      @doc = Nokogiri::XML(open("http://autotrax.duncansolutions.com/baytxstatus/v1/cid/500/area/#{@zone}"))
      @doc.xpath('//ns17:Bay').each do |node|
        @pspace=Space.where(["zone = ? AND bay_number = ?", @zone, node["bayno"]]).first 
          if @pspace.nil? #check for and log spaces reported by duncan and not in our database.
             @count+=1
            LOGGER.info "zone: #{@zone.to_s}  bay: #{node ["bayno"]} is not in database"
            next
          else
              if node["status"] == 'paid'
                if (node["expiryTS"].to_time).strftime(" %I:%M%p ") != @pspace.expires_at   #if status = paid and expiry time is different from expiry time in db, add amount paid to total
                  @pspace.cumulative_total += (node.child["amountPaidCents"].to_f/100)           
                end
                @pspace.status = "active"
                @pspace.expires_at = (node["expiryTS"].to_time).strftime(" %I:%M%p ")
                  else
                    @pspace.status = "expired"    
                    @pspace.expires_at = ""     #if expired reset expires_at to blank
                  end
                  @pspace.last_update = @update_time  
                  @pspace.last_active = @update_time
                  @pspace.save!
              end
          end
        puts @zone.to_s + ' --zone complete'
        @zone+=1
      end 
     LOGGER.info "#{@count} total spaces not found in DB - say somthing to Chad"     
     unreported
  end
  
  def unreported #tag all unreported (due to construction/broken meters...) as inactive 
    @unreported=Space.all
    @unreported.each do |tag|
      if tag.last_active.blank? || tag.last_active.to_datetime < @update_time.to_datetime
        tag.last_update = @update_time
        if tag.last_active.blank?
          tag.last_active = @update.time
        end
        tag.status = "inactive since #{tag.last_active}"
        tag.expires_at = ""
        @unarray << tag.id   #for log - unreported spaces by id
        @unreported_count+=1 #for log - unreported spaces count
        tag.save!
      end
    end
    LOGGER.info "#{@unreported_count} spaces not reporting possibly due to construction"
    LOGGER.info "unreported spaces by id: #{@unarray}"
    export
  end
  
  def export #push all to Socrata
    @payload=[]
    @load=Space.all
    @load.each do |make_res|
       @payload << make_res
    end
    
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
 
Space.new(DB).query 


