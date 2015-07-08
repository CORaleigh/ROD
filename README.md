
### Raleigh Open Data   
##### A collection of Ruby scripts for automating ETL methods on Raleigh data sets

---  
#### Files
**app** - links to each data set's README file

  **[dev_plan](app/dev_plan/README.md)**  - Development plans  

    -  plans.rb  
  **[mobile_311](app/mobile_311/README.md)** - Mobile 311 issues  

    - m311.rb  
    - rebuild_archive.rb  
  **[new_police](app/new_police/README.md)**  - New police data reporting 
 
    - police_data.rb 

  **[parking](app/parking/README.md)** - Metered parking spaces data 
   
    - duncanQuery.rb  
    - parkingseed.rb  
    - space.json  

  **[permit_data](app/permit_data/README.md)**  - Building permit data  

    - permit_chunk.rb  
    - permit_co_update.rb  
    - permit_up.rb  
    - test_permit_up.rb  
    - test_permit_chunk.rb  

  **[pm\_calendar](app/pm_calendar/README.md)**  -  Public meetings calendar data 
 
    - public_meetings_cal.rb  
  **[police\_fix](app/police_fix/README.md)**  - A collection of methods for bringing the historical data set into compliance with police policies and editing/dupe checking

    - police_filter.rb  
    - police_fix.rb
  **[zoning](app/zoning/README.md)**   - re-zoning data
    
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
    - scf_logger.rb - logger for the see click fix script
    - zone_logger.rb - logger for the re-zoning script  
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



