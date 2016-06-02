### Public Meetings Calendar
##### Description 
Public Meetings Google calendar maintained by The Public Affairs department found on this [event webpage](http://www.raleighnc.gov/home/content/ITechWebServices/Articles/Calendar.html)
Calendar ID: 4oqnmtmbp7r21ar09ifb2pnv70@group.calendar.google.com

##### Links  
 [Public Calendar on Socrata](https://data.raleighnc.gov/d/snpm-8ugp)
##### Files  
#### [public_meetings_cal.rb](public_meetings_cal.rb)

    - initialize  - Sets up soda client and global variables
    - process  - Query IRIS, make date fields more human friendly, package up for Socrata
    - push_to_socrata -  push updates to Socrata
    - get_sql - SQL Query

 
>To run manually: cd app/pm_calendar  - must be on OakTree or connected via VPN  
 _public_meetings_cal.rb_  
This will update the entire public calendar requests data set on Socrata as a full replace of existing dataset.
