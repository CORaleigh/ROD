### Permit Data
##### Description 
  
##### Links  
 [City of Raleigh Building Permits on Socrata](https://data.raleighnc.gov/Urban-Planning/City-of-Raleigh-Building-Permits-from-Jan-2000/hk3n-ieai)

##### Files
##### [permit_up.rb](permit_up.rb) - Runs daily Monday - Friday & gets updated records from the last three days
 
  - initialize - Sets up soda client and global variables
  - process - initializes SQL
  - get\_sql\_by\_date - SQL Query with a date variable (currently set to date today - 3 days)
  - transform - Tansforms and uploads data to Socrata. The script gets the last 3 days of permit data from IRIS, renames keys, fixes timestamps (dates) to be more human friendly, concatenates address fields and exports the data to Socrata.

>To run manually: cd app/permit\_data - must be on OakTree or connected via VPN    
 _ruby permit\_up.rb_  3  
This will update permit data from the last three days

---
 
##### [permit_chunk.rb](permit_chunk.rb) -  Use to build entire data set from scratch. Due to the size of the set, transformations and uploads to Socrata must be done in batches (chunks) of ~10000.

  - initialize - Sets up soda client and global variables
  - process - initializes SQL
  - get\_sql - SQL Query with _min_ and _max_ variables  
  - transform - Tansforms and uploads data to Socrata. The script gets the permit data for permits with #'s between _@min_ and _@max_ (_@max_ is determined by adding x - currently set to 10000 to _@min_)  from IRIS, renames keys, fixes timestamps (dates) to be more human friendly, concatenates address fields and exports the data to Socrata.
   
>To run manually: cd app/permit\_data - must be on OakTree or connected via VPN     
 _ruby permit\_chunk.rb_ 1000  
This will get x number of of permits starting with permit #1000

---
 
##### [permit\_co\_update](permit_co_update.rb) -  Use to build entire data set from scratch
 
  - initialize   
>To run manually: cd app/permit\_data - must be on OakTree or connected via VPN     
 _ruby permit\_co\_update.rb_

--- 
##### [test\_permit\_up.rb](permit_chunk.rb) -  Same as permit\_up.rb but uses IRIS test db
##### [test\_permit\_chunk.rb](permit_chunk.rb) - Same as test\_permit\_chunk.rb but uses IRIS test db
 




