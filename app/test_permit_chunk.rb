# test_permit_chunk.rb
# For use with test data-set permit test set on Socrata 
# This script is for bulk uploading permit data to Socrata. It is for starting a new Permit data-set or for when 
# you need to push large (~10,000) records.
# Run this script => ruby permit_chunk.rb followed by an integer representing the 1st permit id you want to upload.
# EX. ruby permit_chunk.rb 1000  => will upload permit data with permit numbers 1000 through 11000.
# This will query the database, concatenate the address fields, rename the column names for a more human readable table,
# adjust the date fields and push up to 10,000 records at a time based on permit id.
 
require 'net/https'
require 'hashie'
require 'rubygems'
require 'sequel'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require 'active_support/time'
require_relative '../lib/logger.rb'
require_relative '../lib/defaults.rb'
require_relative '../lib/helpers.rb'


DB = Sequel.oracle( :database => 'irisdev', :host => 'ucsdevrac1', :port => 1531, :user => configatron.user_dev, :password => configatron.pass_dev)
class ConnectQuery
  
  DATE_FORMAT = '%m/%d/%Y'
  
  def initialize(db, min)
    @client = SODA::Client.new({
   :domain => 'data.raleighnc.gov',
   :app_token => configatron.app_token,
   :username => configatron.client_username,
   :password => configatron.client_pass,
   :content_type => 'text/plain',
   :mime_type => 'JSON',
   :ignore_ssl => true 
      }) 
    
    @db = db
    @view_id = '3rng-pv3r'   #permit data-set code for Socrata
    @payload =[]
    @min=min                 #return permit info starting at permit number
    @max=@min.to_i + 1000    #return permit info ending at permit number + 10,000
    @counter=0
  end

  def stepper              #get sql and start processing
     LOGGER.info "Upload initiated permit numbers  #{@min} - #{@max}"
     @sql = get_sql(@min, @max)
     export
  end
  
  
  def get_sql(min, max)
      <<-SQL 
      SELECT "PERM_GROUPS"."DEVPLAN_DEVPLAN_NAME", "PERM_GROUPS"."GRP_ISSUE_DATE", "PERM_GROUPS"."GRP_PROPOSED_WORK", "PERM_BLDG"."PERM_WORK_TYPE_CODE_DESCR", "PERM_GROUPS"."STREET_NUM", "PERM_GROUPS"."DIR_PRE", "PERM_GROUPS"."STREET_NAME", "PERM_GROUPS"."STREET_TYPE", "PERM_BLDG"."PERMIT_NUM", "PERM_BLDG"."PERM_SQ_FT_FOR_FEE", "PERM_GROUPS"."GRP_BLDG_NUM_STORIES", "PERM_GROUPS"."NCPIN", "PERM_BLDG"."PERM_COST_OF_CONSTRUCTION", "PERM_GROUPS"."GRP_CNTY_PARC_OWNER_NAME", "PERM_BLDG"."PERM_CONTRACTOR_NAME", "PERM_GROUPS"."RPID_LOT", "PERM_GROUPS"."PERM_C_BLDG_CO_DATE", "PERM_BLDG"."PERM_AUTHORIZED_WORK", "PERM_GROUPS"."GRP_B_NUM_DWEL_UNITS_TOTAL", "PERMIT_CENSUS_LAND_USE_CODES"."CENSUS_LAND_USE_CODE_DESCR", "PARCELS"."CNTY_ACCT_NUM", "PERM_GROUPS"."GRP_STATUS", "PERM_GROUPS"."STREET_SUITE", "PARCELS"."PARC_COUNTY", "CITY_LIMITS_CODES"."IN_OUT_CITY_LIMITS_DESCR", "PERM_GROUPS"."DIR_SUF", "ADDRESSES"."CITY", "ADDRESSES"."STATE", "ADDRESSES"."ZIP", "LAND_USE_CODES"."LANDUSECODE_DESCR"
      FROM   ((((("IRIS"."PERM_GROUPS" "PERM_GROUPS" INNER JOIN "IRIS"."PERM_BLDG" "PERM_BLDG" ON ("PERM_GROUPS"."GROUP_NUM"="PERM_BLDG"."GROUP_NUM") AND ("PERM_GROUPS"."GRP_TRANS_NUM"="PERM_BLDG"."PERM_TRANS_NUM")) INNER JOIN "IRIS"."PARCELS" "PARCELS" ON ("PERM_GROUPS"."RPID_LOT"="PARCELS"."RPID_LOT") AND ("PERM_GROUPS"."RPID_MAP"="PARCELS"."RPID_MAP")) INNER JOIN "IRIS"."PERMIT_CENSUS_LAND_USE_CODES" "PERMIT_CENSUS_LAND_USE_CODES" ON "PERM_GROUPS"."GRP_CENSUS_LAND_USE_CODE"="PERMIT_CENSUS_LAND_USE_CODES"."CENSUS_LAND_USE_CODE") INNER JOIN "IRIS"."ADDRESSES" "ADDRESSES" ON (("PERM_GROUPS"."ADDRESS_ID"="ADDRESSES"."ADDRESS_ID") AND ("PARCELS"."RPID_MAP"="ADDRESSES"."RPID_MAP")) AND ("PARCELS"."RPID_LOT"="ADDRESSES"."RPID_LOT")) INNER JOIN "IRIS"."CITY_LIMITS_CODES" "CITY_LIMITS_CODES" ON "PARCELS"."PARC_IN_OUT_CITY_LIMITS"="CITY_LIMITS_CODES"."IN_OUT_CITY_LIMITS") INNER JOIN "IRIS"."LAND_USE_CODES" "LAND_USE_CODES" ON "PARCELS"."PARC_LAND_USE"="LAND_USE_CODES"."LAND_USE_CODE"
      WHERE  ("PERM_GROUPS"."GRP_STATUS"='A' OR "PERM_GROUPS"."GRP_STATUS"='I' OR "PERM_GROUPS"."GRP_STATUS"='V' )
       and "PERM_BLDG"."PERMIT_NUM" between #{min} and #{max}
      ORDER BY "PERM_BLDG"."PERMIT_NUM" 
      SQL
  end
    
  def export  #process the data and send to Socrata

    result_objects=@db[@sql].all    
    result_objects.each do |h|
   ############rename keys to make human friendly
   h.rewrite(:devplan_devplan_name => :development_plan_name,
            :grp_issue_date  =>    :issue_date,
            :grp_proposed_work => :proposed_work,
            :perm_work_type_code_descr => :work_type_description, 
            :permit_num => :permit_number,
            :perm_sq_ft_for_fee => :square_feet,
            :grp_bldg_num_stories => :number_of_stories,
            :ncpin => :nc_pin,
            :perm_cost_of_construction => :cost_of_construction,
            :grp_cnty_parc_owner_name => :owner_name,
            :perm_contractor_name => :contractor_name,
            :rpid_lot => :rpid_lot,
            :perm_c_bldg_co_date => :building_date,
            :perm_authorized_work => :authorized_work,
            :grp_b_num_dwel_units_total => :dwelling_units_total,
            :census_land_use_code_descr => :land_use_code_description,
            :cnty_acct_num => :county_account_number,
            :grp_status => :status,
            :parc_county => :county,
            :in_out_city_limits_descr => :in_out_city_limits,
            :landusecode_descr => :land_use_code
             
 )


    ##############set proper date_type
           h[:issue_date]=h[:issue_date].to_datetime
              if !h[:building_date].nil? 
                h[:building_date] =  h[:building_date].to_datetime
              end 
              
    ##############concatenate address fields to Location 1       
        temp_address = {:address =>(h[:street_num].to_s << ' ' << 
                                               h[:dir_pre].to_s << ' ' << 
                                               h[:street_name].to_s << ' ' << 
                                               h[:street_type].to_s << ' ' << 
                                               h[:dir_suf].to_s << ' ' << 
                                               h[:city].to_s <<  " NC  " << 
                                               h[:zip].to_s ).squeeze(' ')}
     
        package = h.merge!(temp_address)
        
        @payload << package 
        @counter+=1

    end
      response = @client.post(@view_id, @payload)         #upload to Socrata

      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'

      LOGGER.info "Update complete using test_permit_chunk.rb"
      LOGGER.info "................. #{response["Errors"]} Errors"
      LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
      LOGGER.info "................. #{response["Rows Created"]} Rows Created"
      LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
   end 
end
 
ConnectQuery.new( DB, ARGV[0] ).stepper 


