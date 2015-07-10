 
require 'httparty'
require 'net/https'
require 'hashie'
require 'rubygems'
require 'sequel'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require 'active_support/time'
require_relative '../../lib/cop_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'
 
 
DB = Sequel.oracle( :database => configatron.cops_db, :host => configatron.cops_host, :port => 1531, :user => configatron.cops_user, :password => configatron.cops_pass)

class Cops

  def initialize(db) 
    @client = SODA::Client.new({
      :domain => 'data.raleighnc.gov',
      :app_token => configatron.app_token,
      :username => configatron.client_username,
      :password => configatron.client_pass,
      :content_type => 'text/plain',
      :mime_type => 'JSON',
      :ignore_ssl => true }) 

    @db = db
    @view_id = 'xxx-xxx'           #permit data-set code for Socrata
    #@view_id = 'vhs9-de7d'            #working permit data set
    @package = []
    @num_arry = []
    @counter=0 
  end

  def process 
    LOGGER.info "Update for police data initiated."
    get_co  
  end
 
  def get_co  
      

      lookup
  end

  def lookup 
     
  end

  def transform(object)
    object.rewrite( 
              )
    
  end

  def export(set)
    response = @client.post(@view_id, set)
    puts response["Errors"].to_s + 'Errors'
    puts response["Rows Deleted"].to_s + ' Rows Deleted'
    puts response["Rows Created"].to_s + ' Rows Created' 
    puts response["Rows Updated"].to_s + ' Rows Updated'
    LOGGER.info "Permit CO dates updated "
    LOGGER.info "................. #{response["Errors"]} Errors"
    LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"      
    LOGGER.info "................. #{response["Rows Created"]} Rows Created"
    LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
  end 

  def get_sql(num) 
      <<-SQL 
        
      SQL
  end 
end
 
Cops.new(DB).process


