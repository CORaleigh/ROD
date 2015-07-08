#development plans
#https://data.raleighnc.gov/Urban-Planning/Development-Plans/4fws-529h


require 'net/https'
require 'hashie'
require 'rubygems'
require 'sequel'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require 'active_support/time'
require 'csv'
require_relative '../../lib/plan_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'


DB = Sequel.oracle( :database => configatron.db, :host => configatron.host, :port => 1531, :user => configatron.user, :password => configatron.pass)

class ConnectQuery

  DATE_FORMAT = '%m/%d/%Y'

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

    @db = db
    @view_id = 'hyba-m4ki'   # data-set code for Socrata
    @payload =[]
    @package =[]
    @date = (Date.today - 180.days).strftime(ConnectQuery::DATE_FORMAT)
  end

  def stepper              #get sql and start processing
     LOGGER.info "Development Plans update initiated"
     @sql = get_sql(@date) 
     process
  end
def process
 
    result_objects=@db[@sql].all   
    result_objects.each do |fix|

      fix[:devplan_id] = fix[:devplan_id].to_i
      fix[:lots_req] = fix[:lots_req].to_i
      fix[:lots_apprv] = fix[:lots_apprv].to_i
      fix[:lots_req] = fix[:lots_req].to_i
      fix[:lots_apprv] = fix[:lots_apprv].to_i
      fix[:acreage] = fix[:acreage].truncate(2).to_s('F')
      fix[:lots_rec] = fix[:lots_rec].to_i
      fix[:units_apprv] = fix[:units_apprv].to_i
      fix[:units_req] = fix[:units_req].to_i
      fix[:sq_ft_req] = fix[:sq_ft_req].to_i
      if !fix[:submitted].blank? 
        fix[:submitted] =  (fix[:submitted].to_datetime).strftime("%Y-%m-%d")
      end 
      if !fix[:approved].blank?
        fix[:approved] =  (fix[:approved].to_datetime).strftime("%Y-%m-%d")
      end 
      if !fix[:updated].blank?
        fix[:updated] =  (fix[:updated].to_datetime).strftime("%Y-%m-%d")
      end 
      if !fix[:inserted].blank?
        fix[:inserted] =  (fix[:inserted].to_datetime).strftime("%Y-%m-%d")
      end
      fix.rewrite( :address => ("Location 1").to_sym )
      
      @payload << fix
    end 
    #tocsv
    export
     
end
 
  def tocsv 
    CSV.open("DPlan.csv", "wb") do |csv|
      csv << @payload.first.keys # adds the attributes name on the first line
      @payload.each do |hash|
        csv << hash.values
      end
    end
  end
  
  def get_sql(date)
    <<-SQL
    SELECT
        NVL(dv.DEVPLAN_ID, 0) as devplan_id,
        NVL(dv.plan_name, ' ') as plan_name,
        NVL(dv.plan_number, ' ') as plan_number,
        NVL(dv.case_year, ' ') as case_year,
        NVL(dv.plan_type, ' ') as plan_type,
        NVL(dv.major_street, ' ') as major_street,
        NVL(dv.acreage, 0) as acreage,
        NVL(dv.lots_req, 0) as lots_req,
        NVL(dv.lots_apprv, 0) as lots_apprv,
        NVL(dv.lots_rec, 0) as lots_rec,
        NVL(dv.units_req, 0) as units_req,
        NVL(dv.UNITS_APPRV, 0) as units_apprv,
        NVL(dv.SQ_FT_REQ, 0) as sq_ft_req,
        NVL(dv.ZONING, ' ') as zoning,
        NVL(dv.CAC, ' ') as cac,
        NVL(dv.PLANNER, ' ') as planner,
        NVL(dv.OWNER, ' ') as owner,
        NVL(dv.OWNER_PHONE, ' ') as owner_phone,
        NVL(dv.ENGINEER, ' ') as engineer,
        NVL(dv.ENGINEER_PHONE, ' ') as engineer_phone,
        NVL(TO_CHAR(dv.SUBMITTAL_DATE, 'YYYYMMDD'), ' ') as SUBMITTED,
        NVL(TO_CHAR(dv.APPROVAL_DATE, 'YYYYMMDD'), ' ') as APPROVED,
        CASE dv.STATUS WHEN 'A' THEN 'Active'
        WHEN 'W' THEN 'Withdrawn'
        WHEN 'P' THEN 'Pending'
        WHEN 'S' THEN 'Sunset'
        WHEN 'D' THEN 'Denied'
        WHEN 'N' THEN 'Review In Progress'
        ELSE ' ' END as status,
        NVL(TO_CHAR(dp.update_date, 'YYYYMMDD'), ' ') as UPDATED,
        NVL(TO_CHAR(dp.insertion_date, 'YYYYMMDD'), ' ') as INSERTED,
        address.address
        from
        iris.devplans_view dv, iris.development_plans dp,
        (select devplan_id, a.STREET_NUM ||' '|| trim( s.street_dir_pre || ' ' || s.street_name || ' ' || s.street_type) || ', RALEIGH, NC ' || 
                  CASE a.ZIP WHEN '000000' THEN '' ELSE a.ZIP END as address from 
        (select devplan_id, max(a.address_id) as address_id from iris.devplans_case_history dch, iris.addresses a 
        where dch.rpid_map = a.rpid_map and dch.rpid_lot = a.rpid_lot group by devplan_id) d1, iris.addresses a, iris.streets s
        where a.address_id = d1.address_id and a.street_id = s.street_id) address where dv.devplan_id = address.devplan_id 
        and dv.devplan_id = dp.devplan_id 
        order by dv.devplan_id desc
    SQL
  end

  
  def export  #process the data and send to Socrata 
      response = @client.post(@view_id, @payload)         #upload to Socrata
      puts
      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'

      LOGGER.info "Upload complete for dev plans"
      LOGGER.info "................. #{response["Errors"]} Errors"
      LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
      LOGGER.info "................. #{response["Rows Created"]} Rows Created"
      LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"

   end
end

ConnectQuery.new(DB).stepper