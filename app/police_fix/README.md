### Police Fix
##### Description 
Ruby scripts for fixing and editing the police data set to bring into compliance with police policies  
##### Links  
 [Police incident data on Socrata](https://data.raleighnc.gov/Police/Police-Incident-Data-from-Jan-1-2005-Master-File/csw9-dd5k)  
[Police beats to district table](../docs/beats.csv)  
[police\_data\_moved.csv](../docs/police_data_moved.csv) - example file with coordinate points moved to street center-line. Includes police records thru June 27 2015.

##### Files
##### [police_filter.rb](police_filter.rb) -  collection of methods & filters for police data set to bring into compliance with police data policies  
   
    - initialize - Sets up soda client and global variables + an array of strings  to be used in the filter method  
    - process -  Switch to change/daisy chain methods
    - beat_lookup - Beat to district table    
    - beat_to_district - Reads CSV file and converts beats to districts based on beat_lookup
    - filter -  Reads CSV file and deletes coordinates based on @filter strings
    - split_csv_coords  -  Reads CSV file and splits coordinate column into individual lat and lng columns, sends the new hash to 'to_csv' method to write to a new CSV for further processing.
    - to_csv - Writes a hash to a CSV file
    - join_csv_coords -  Reads CSV file and concatenates two columns (NEAR_Y & NEAR_X) into a single column, fixes the syntax, strips out extraneous fields and pushes the new hash up to Socrata
    - load_csv - loads a CSV and converts it to a hash
    - load_psv -  loads a PSV (pipe separated value) and converts it to a hash
    - purge -   Reads a CSV file and adds a hash  (":deleted" =>  true) to each row in the set. Socrata recognizes this when you upload and deletes the row.  
    - replace -  Re-uploads CSV data to Socrata - Socrata will recognize any duplicates and ignore them. Must have a unique api endpoint row identifier ( for the police data set that is 'INC NO', see Socrata docs for more info on row identifiers)
    - export - push updates to data set on Socrata.     
  
>To run manually: cd app/police\_filter  - must be on OakTree or connected via VPN    
 _ruby police\_filter.rb_ 
 
---
 
##### [police_fix.rb](police_fix.rb) -  single use script for removing duplicates from the master police data (2013) set on Socrata. The data is first deleted from the set on Socrata and then replaced.
    - initialize - Sets up soda client and global variables 
    - process - Switch to run purge or replace methods
    - purge - Reads a CSV file and adds a hash  (":deleted" =>  true) to each row in the set. Socrata recognizes this when you upload and deletes the row.    
    - replace - Re-uploads CSV data to Socrata - Socrata will recognize any duplicates and ignore them. Must have a unique api endpoint row identifier ( for the police data set that is 'INC NO', see Socrata docs for more info on row identifiers)
    - export - push updates to data set on Socrata.

>To run manually: cd app/police\_fix  - must be on OakTree or connected via VPN    
 _ruby police\_fix.rb_  

 

