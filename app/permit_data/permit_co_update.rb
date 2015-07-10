 
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
require_relative '../../lib/permit_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'
 
 
DB = Sequel.oracle( :database => configatron.db, :host => configatron.host, :port => 1531, :user => configatron.user, :password => configatron.pass)

class Permit_co_date

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
    @view_id = 'hk3n-ieai'           #permit data-set code for Socrata
    #@view_id = 'vhs9-de7d'            #working permit data set
    @package = []
    @num_arry = []
    @counter=0 
  end

  def process 
    LOGGER.info "Update for building permits CO date initiated."
    get_co #get permit co dates from existing set on socrata
  end
 
  def get_co #get all permits from Socrata with blank building_co_date
      response = @client.get(@view_id, 
          "$select" => :permit_number,
          "$where" => "building_date IS NULL",
          "$limit" => 50000,
          "$order" => :permit_number,
          "$offset" => 0)
      response.each do |pnum|
        @num_arry << pnum["permit_number"]
      end
      lookup
  end

  def lookup # query iris in groups of 1000 (limit for SQL)
    @num_arry.each_slice(1000) do |na|
      nas = na.join(', ')
      sql = get_sql(nas)
      result = @db[sql].all
      result.each do |r|
          transform(r)
          @package << r
          @counter +=1 
      end      
    end
      if @package.size == 0
        LOGGER.info "Nothing to see here!"
        LOGGER.info "Permit CO dates are all up to date"
      else
        export(@package)
      end  
  end

  def transform(object)
    object.rewrite(:permit_num => :permit_number,
              :perm_c_bldg_co_date => :building_date,
              :grp_status => :status
              )
    object[:building_date] =  object[:building_date].to_datetime 
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
        SELECT 
          "PERM_BLDG"."PERMIT_NUM","PERM_GROUPS"."PERM_C_BLDG_CO_DATE","PERM_GROUPS"."GRP_STATUS"
        FROM   ((((("IRIS"."PERM_GROUPS" "PERM_GROUPS" INNER JOIN "IRIS"."PERM_BLDG" "PERM_BLDG" ON ("PERM_GROUPS"."GROUP_NUM"="PERM_BLDG"."GROUP_NUM") 
          AND ("PERM_GROUPS"."GRP_TRANS_NUM"="PERM_BLDG"."PERM_TRANS_NUM")) 
          INNER JOIN "IRIS"."PARCELS" "PARCELS" ON ("PERM_GROUPS"."RPID_LOT"="PARCELS"."RPID_LOT") 
          AND ("PERM_GROUPS"."RPID_MAP"="PARCELS"."RPID_MAP")) 
          INNER JOIN "IRIS"."PERMIT_CENSUS_LAND_USE_CODES" "PERMIT_CENSUS_LAND_USE_CODES" 
          ON "PERM_GROUPS"."GRP_CENSUS_LAND_USE_CODE"="PERMIT_CENSUS_LAND_USE_CODES"."CENSUS_LAND_USE_CODE") 
          INNER JOIN "IRIS"."ADDRESSES" "ADDRESSES" ON (("PERM_GROUPS"."ADDRESS_ID"="ADDRESSES"."ADDRESS_ID") 
          AND ("PARCELS"."RPID_MAP"="ADDRESSES"."RPID_MAP")) AND ("PARCELS"."RPID_LOT"="ADDRESSES"."RPID_LOT")) 
          INNER JOIN "IRIS"."CITY_LIMITS_CODES" "CITY_LIMITS_CODES" ON "PARCELS"."PARC_IN_OUT_CITY_LIMITS"="CITY_LIMITS_CODES"."IN_OUT_CITY_LIMITS") 
          INNER JOIN "IRIS"."LAND_USE_CODES" "LAND_USE_CODES" ON "PARCELS"."PARC_LAND_USE"="LAND_USE_CODES"."LAND_USE_CODE"
        WHERE  "PERM_BLDG"."PERMIT_NUM" IN  (#{num}) 
          AND "PERM_GROUPS"."PERM_C_BLDG_CO_DATE" IS NOT NULL
      SQL
  end 
end
 
Permit_co_date.new(DB).process


