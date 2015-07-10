### Re-Zoning Requests
##### Description 
Submitted re-zoning requests, including submitter or petitioner, date of submission and latest action, size of land concerned, re-zoning "Remarks," and other details.  

##### Links  
 [Re-Zoning Requests on Socrata](https://data.raleighnc.gov/Urban-Planning/Re-Zoning-Requests/k4is-g3ap)
##### Files  
#### [zone.rb](zone.rb)

    - initialize  - Sets up soda client and global variables
    - process  - Query IRIS, make date fields more human friendly, package up for Socrata
    - push_to_socrata -  push updates to Socrata
    - get_sql - SQL Query

 
>To run manually: cd app/zoning  - must be on OakTree or connected via VPN  
 _ruby  zone.rb_  
This will update the re-zoning requests data set on Socrata