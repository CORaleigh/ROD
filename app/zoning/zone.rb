
# zone.rb
# Data set contains all zoning data starting with 1/1/2000 - can be altered in the SQL below.
# This script uploads all zoning data to socrata using put to replace the entire set. This data set does not have a consistant unique identifier
# so it cannot be updated/appended.
# To run => ruby zone.rb

require 'net/https'
require 'hashie'
require 'rubygems'
require 'sequel'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require 'active_support/time'
require_relative '../../lib/zone_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'
 
 
DB = Sequel.oracle( :database => configatron.db, :host => configatron.host, :port => 1531, :user => configatron.user, :password => configatron.pass)


class UpdateZones

  DATE_FORMAT = '%m/%d/%Y'

  def initialize(db) 
    @client = SODA::Client.new({
      :domain => 'data.raleighnc.gov',
      :app_token => configatron.app_token,
      :username => configatron.client_username,
      :password => configatron.client_pass,
      :content_type => 'text/plain',
      :mime_type => 'JSON',
      :ignore_ssl => true }) 
    @db=db
    @view_id = 'k4is-g3ap'           #permit data-set code for Socrata
    @payload =[]
    @counter = 0
  end

  def process 
    #LOGGER.info "Update initiated. Start date #{@date}"
    @sql = get_sql
    result_objects=@db[@sql].all 
    result_objects.each do |h|
      
            #make more friendly dates
            h[:"submittal date"] = h[:"submittal date"].to_datetime
            h[:"public hearing date"] = h[:"public hearing date"].to_datetime
            h[:"withdraw date"] = h[:"withdraw date"].to_datetime
            h[:"effect date"].nil? ?   " " : h[:"effect date"] = h[:"effect date"].to_datetime
            h[:"120 day expiration date"] = h[:"120 day expiration date"].to_datetime 
            h[:"2 year experation date"] = h[:"2 year experation date"].to_datetime
 
        @payload << h
        @counter+=1    

    end
    puts @payload.to_json
    #push_to_socrata
  end

   def push_to_socrata 
       response = @client.put(@view_id, @payload) #use put here to replace entire data set
       puts response["Errors"].to_s + 'Errors'
       puts response["Rows Deleted"].to_s + ' Rows Deleted'
       puts response["Rows Created"].to_s + ' Rows Created'
       puts response["Rows Updated"].to_s + ' Rows Updated'
       LOGGER.info "Update complete using zone.rb"
       LOGGER.info "................. #{response["Errors"]} Errors"
       LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
       LOGGER.info "................. #{response["Rows Created"]} Rows Created"
       LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
  end

  def get_sql 
      <<-SQL 
       SELECT z.ZPYEAR as "Zoning Petition Year", z.ZPNUM as "Zoning Petition Number", z.ZP_SUBMITTAL_DATE as "Submittal Date", z.PHDATE as "Public Hearing Date",
       z.ZP_WITHDRAW_DATE as "Withdraw Date", z.EFFECT_DATE as "Effect Date",
       z.EXPIRE_DATE as "120 Day Expiration Date", z.ZP_WAIT_PERIOD_END_DATE as "2 Year Experation Date",
       z.GRP_TRANS_NUM as "Transaction Number" , z.ORD_NUMBER as "Ordinance Number", z.ZP_PETITION_ACRES as "Zoning Petition Acres", z.REMARKS as "Remarks",
       z.INSERTION_USER_ID as "Received By", z.UPDATE_USER_ID as "Last Revised",
       (Select Trim(Trim(s.street_dir_pre) || ' ' ||
                    Trim(s.street_name) || ' ' ||
                    Trim(s.street_dir_suf) || ' ' ||
                    Trim(s.street_type))
        FROM IRIS.STREETS s
        WHERE s.STREET_ID = z.STREET_ID) as "Location",
        (Select wm_concat((CASE cc.CCACTION
                                WHEN 'A' THEN 'Approved'
                                WHEN 'C' THEN 'Committee'
                                WHEN 'D' THEN 'Denied'
                                WHEN 'H' THEN 'Holding'
                                WHEN 'R' THEN 'Resubmitted'
                                WHEN 'W' THEN 'Waiver Granted'
                                WHEN 'X' THEN 'Waiver Denied'
                                ELSE 'N/A'
                                END ) || '  ' || cc.ccdate )
       FROM IRIS.ZP_CC_ACTIONS cc
       WHERE z.ZPYEAR = cc.ZPYEAR AND z.ZPNUM = cc.ZPNUM) as "City Council Action(s)",
       (Select wm_concat((CASE pc.PCACTION
                                WHEN 'A' THEN 'Approved'
                                WHEN 'C' THEN 'Committee'
                                WHEN 'D' THEN 'Denied'
                                WHEN 'H' THEN 'Holding'
                                WHEN 'N' THEN 'No Action'
                                WHEN 'R' THEN 'Resubmitted'
                                WHEN 'W' THEN 'Waiver Granted'
                                WHEN 'X' THEN 'Waiver Denied'
                                ELSE 'N/A'
                                END ) || '  ' || pc.pcdate)
       FROM IRIS.ZP_PC_ACTIONS pc
       WHERE z.ZPYEAR = pc.ZPYEAR AND z.ZPNUM = pc.ZPNUM) as "Planning Commission Action(s)",
          (Select wm_concat(zp.PETITIONER  || '  ' || (select CLIENT_NAME from iris.CLIENTS where  CLIENT_ID = zp.PETITIONER ) ||'  ')
       FROM IRIS.ZP_PETITIONER zp
       WHERE z.ZPYEAR = zp.ZPYEAR AND z.ZPNUM = zp.ZPNUM) as "Petitioner(s)",
          (Select wm_concat((select DRAIN_BASIN_DESCR from iris.DRAINAGE_BASINS where DRAIN_BASIN = db.DRAIN_BASIN) || '   ' || db.ZPDRBAIN_ACRES)
       FROM
           IRIS.ZP_DRAIN_BASIN_ACRES db
       WHERE z.ZPYEAR = db.ZPYEAR AND z.ZPNUM = db.ZPNUM) as "Drain Basin(s)",
          (Select wm_concat((select COMPREHENSIVE_PLAN_DIST_DESCR from iris.comprehensive_plan_districts where COMPREHENSIVE_PLAN_DIST = cp.COMPREHENSIVE_PLAN_DIST) || '  '||cp.zpcompplan_acres)
       FROM IRIS.ZP_COMP_PLAN_ACRES cp
       WHERE z.ZPYEAR = cp.ZPYEAR AND z.ZPNUM = cp.ZPNUM) as "COMPREHENSIVE PLAN DISTRICTS",
          (Select wm_concat((select CAC_CODE_DESCR from iris.cac_codes where cac_code = cac.CAC_CODE ) || '  ' || cac.ZPCAC_ACRES)
       FROM IRIS.ZP_CAC_ACRES cac
       WHERE z.ZPYEAR = cac.ZPYEAR AND z.ZPNUM = cac.ZPNUM)as "Advisory Committee Areas"
       FROM IRIS.ZONING_PETITIONS z
       WHERE z.ZP_SUBMITTAL_DATE >= to_date ('2000-01-01', 'yyyy-mm-dd')
       ORDER BY z.ZPYEAR, z.ZPNUM
      SQL
  end

end
 
UpdateZones.new(DB).process