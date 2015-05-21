#m331.rb 

require 'net/https'
require 'uri'
require 'hashie'
require 'rubygems'
require 'json'
require 'soda/client'
require 'configatron'      #configatron for private usernames, passwords ...
require 'date'
require 'active_support/time'
#require 'HTTParty'
require 'csv'
require 'rest_client'
require 'rexml/document'
require 'crack'
require 'normalic'
require_relative '../../lib/m311_logger.rb'
require_relative '../../lib/defaults.rb'
require_relative '../../lib/helpers.rb'

class MobileUp 

  def initialize 
      @client = SODA::Client.new({
        :domain => 'data.raleighnc.gov',
        :app_token => configatron.app_token,
        :username => configatron.client_username,
        :password => configatron.client_pass,
        :content_type => 'text/plain',
        :mime_type => 'JSON',
        :ignore_ssl => true }) 
      #@view_id = "98in-qmzx" #working set
      @view_id = "h5i3-8nha"
      @package=[]
      @owneradd=[]
      get_token 
      @base_image_url = "http://map2.Mobile311.com/Mobile311/Files/File.aspx?id="
      @date_today = Date.today.strftime("%Y-%m-%d")
      
  end
 
  def get_token
    response = RestClient.post( 'https://map.mobile311.com/ws7/t.asmx/f',
                                :json=>{"cmd"=>"signin","username"=>"#{configatron.m311_username}","password"=>"#{configatron.m311_pass}"}.to_json)
    @data = Crack::XML.parse(response)
    j = @data["TaskResponse"]["Data"] 
    tok = Crack::JSON.parse(j)
    @token = tok["Token"]  
  end

  def get_data
    response = RestClient.post( 'https://map.mobile311.com/ws7/t.asmx/f',
                                  :json=>{"cmd" => "findworkrequestsbymodifieddate","token"=>"#{@token}","fromdate"=>"2015-1-1",
                                  "todate"=>"#{@date_today}","gethistory" => true,"getfiles" => false}.to_json) 
    data=Crack::XML.parse(response)
    xml_res=data["TaskResponse"]["Data"] 
    set=JSON.parse(xml_res)
    
    set["WorkRequests"].each do |object|
       if object["statusname"] == 'Flagged' || object ["statusname"] == "Completed" #only get objects with 'flagged' or 'completed' status
           
           object.rewrite( "workrequestid" => "Id",
                           "worktypename" => "Work Type",
                           "posteddate" => "Post Date",
                           "collecteddate" => "Date Flagged",
                           "modifieddate" => "Modified Date",
                           "statusname" => "Status",
                           "latitude" => "Latitude",
                           "longitude" => "Longitude",
                           "description" => "Description",
                           "comments" => "Comments",
                           "priority" => "Priority",
                           "address" => "Violation Address"

                        )
           #add empty keys => values to object 
           object["Property Owner Name"] = " "
           object["Property Owner Address"] = " "
           object["City1"] = " "
           temp_flagged ={"Flagged By" => (object["username"])}
           object.merge!(temp_flagged)
          
           #fix date objects
           unless object["Post Date"].nil?
              object["Post Date"] = date_fixer(object["Post Date"]) 
           end
           unless object["Date Flagged"].nil?
              object["Date Flagged"] = date_fixer(object["Date Flagged"])
           end
           unless object["Modified Date"].nil?
              object["Modified Date"] = date_fixer(object["Modified Date"])
           end 

           #look up owner name and address       
           addr =   object["Violation Address"]
           lookup(addr)
           object["Property Owner Name"] = @ownername 
           object["Property Owner Address"] = @owneradd
           object["City1"] = @city1
           
           #fix irritating (null) for comments key
           if object["Comments"] == "(null)"
              object["Comments"] = " "
            end

           #add photo url if exists
            if object["hasphoto"] == true
              photo_url = @base_image_url + object["Id"].to_s
              photo = {"Photo" => "#{photo_url}"}
            else
              photo = {"Photo" => " "}
            end
            object.merge!(photo)
            #puts object["Photo"]

           #strip extranious fields from object
           object.except!( "authorized","hasphoto","gislayer","uniqueclientid","color","clientname","type","pointy","pointx","hyperlink",
                   "clientid","totalrecords","addresssource","assetid","guid","requesttitle","worktypeid","userid", "statusid",
                   "assigneduserids", "workgroupname", "longtitude","citizenrequest","citizenphonenumber","citizenemail","citizenfirstname","citizenlastname", "workrequestemployees",
                    "workrequestequipment", "workrequestmaterials", "city", "state", "zip", "customvalues", "address","username","citizenrequest")
           #package it all up
          print '.'
          @package << object.to_hash 
       end   
    end 
        export   
                       
  end

  def lookup(add)    #clean up address and query arcgis rest service for name and addresses
      normadd=Normalic::Address.parse("#{add}")
      nadds=(normadd.to_s).gsub(/[.,]/,'')

      data = JSON.parse RestClient.post "http://maps.raleighnc.gov/arcgis/rest/services/Parcels/MapServer/exts/PropertySOE/RealEstateSearch", {
          'type' => 'address',
          'values' => "['#{nadds}']",
          'f' => 'json' }
      info = data["Accounts"]
      info.each do |p|
        @ownername = p["owner"]
        @owneradd = p["mailAddress1"]
        @city1 = p["mailAddress2"]
      end                              
  end

  def export #push all to Socrata
      response = @client.post(@view_id, @package)         #upload to Socrata
      puts response["Errors"].to_s + ' Errors'
      puts response["Rows Deleted"].to_s + ' Rows Deleted'
      puts response["Rows Created"].to_s + ' Rows Created'
      puts response["Rows Updated"].to_s + ' Rows Updated'
      LOGGER.info "Update complete using m311_3.rb"
      LOGGER.info "................. #{response["Errors"]} Errors"
      LOGGER.info "................. #{response["Rows Deleted"]} Rows Deleted"
      LOGGER.info "................. #{response["Rows Created"]} Rows Created"
      LOGGER.info "................. #{response["Rows Updated"]} Rows Updated"
  end

  def tocsv 
    CSV.open("Mobile311.csv", "wb") do |csv|
      csv << @package.first.keys # adds the attributes name on the first line
      @package.each do |hash|
        csv << hash.values
      end
    end
  end

end

MobileUp.new.get_data


