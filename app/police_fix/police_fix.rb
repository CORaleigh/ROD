#single use script for removing duplicates from the master police data (2013) set on Socrata
#using a copy of the 2013 data set, this will first remove all rows from the master set for the year 2013
#the duplicate files will remain but will be updated in the replace method
#this file can be modified to replace duplicates in other sets
#!!!always run aginst a working data set!!!!#

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

    @view_id = 'Add working set code here'   #permit working data-set code for Socrata
  
    http = Net::HTTP.new(@host, @port) #fix timeout issues
    http.read_timeout = 500

  end
  def process #switch 
    #purge
    replace
  end


  def purge #remove all 2013 police data
    @payload =[]               
    csv_data = CSV.read("p2013.csv", "r")   #csv file should be placed in police_fix folder or the path should be changed to reflect another location
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @payload = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    @payload.each do |remove|
      addon = {":deleted" =>  true}  #all rows with a unique identifier and a {":deleted" => true } hash will be deleted from socrata
      remove.merge!(addon)
    end
    puts 'purging police records....'
    export
  end

  def replace #repost all police 2013 data
    @payload = []
    csv_data = CSV.read("p2013.csv", "r")    #csv file should be placed in police_fix folder or the path should be changed to reflect another location
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    @payload = string_data.map {|row| Hash[*headers.zip(row).flatten] }
    puts 'pushing police records....'
    export
  end



  def export  #process the data and send to Socrata

      response = @client.post(@view_id, @payload)         #upload to Socrata & log response
      puts
      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'

   end
end

FixPolice.new.process
