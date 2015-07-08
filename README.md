<div style="color:black;text-align:center;background:orange;padding:8px;font-size:21px;border-radius: 25px;">
<b>R</b>aleigh <b>O</b>pen <b>D</b>ata <br> 
  <span style = "font-size:18px;">
     A collection of Ruby scripts for automating ETL methods on Raleigh data sets
  </span>
</div>
###Files

**app** - links to each data set's README file

  [dev_plan](app/dev_plan/README.md)  - Development plans  

    -  plans.rb  
  [mobile_311]() - Mobile 311 issues  

    - m311.rb  
    - rebuild_archive.rb  
  [new_police]()  - New police data reporting 
 
    - police_data.rb   
  [parking]() - Metered parking spaces data 
   
    - duncanQuery.rb  
    - parkingseed.rb  
    - space.json  

  [permit\_data]()  - Building permit data  

    - permit_chunk.rb  
    - permit_co_update.rb  
    - permit_up.rb  
    - test_permit_up.rb  
    - test_permit_chunk.rb  

  [pm\_calendar]()  -  Public meetings calendar data 
 
    - public_meetings_cal.rb  
  [police\_fix]()  - A collection of methods for bringing the historical data set into compliance with police policies and editing/dupe checking

    - police_filter.rb  
    - police_fix.rb
  [zoning]()   - re-zoning data
    
    - zone.rb

**db**

	- databases go here
**docs**

	random documents for creating a new dataset on Socrata or for use in editing an existing data set. Ex permit_headers.csv is a csv of all of the column names for the permit data set
**lib**

    - cal_logger.rb - logger for public meetings calendar script
    - cop_logger.rb - logger for new_police script   
    - m311_logger.rb - logger for Mobile 311 script
    - permit_logger.rb - logger for building permits script
    - plan_logger.rb - logger for development plans script
    - scf\_logger.rb - logger for the see click fix script
    - zone\_logger.rb - logger for the re-zoning script  
    - defaults.rb - configatron environmental variables - keeps secrets secret         
    - helpers.rb - helper files for adjusting dateTime elements & extending the Hash Class for the renaming of hash keys


**log** - log files for all scripts

**shell scripts** - shell scripts run from a cron job to update the data sets	

    - calendar.sh
    - daily_permits.sh
    - dev_plan.sh
    - m311.sh
    - monthly_zoning.sh
    - scf.sh