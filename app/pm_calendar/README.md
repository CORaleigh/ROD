### Public Meetings Calendar
##### Description 
Public Meetings Google calendar maintained by The Public Affairs department found on this [event webpage](http://www.raleighnc.gov/home/content/ITechWebServices/Articles/Calendar.html)
Calendar ID: 4oqnmtmbp7r21ar09ifb2pnv70@group.calendar.google.com

This job copies calendar events from the Google Calendar and creates a row for each event. The most recent version of this job also identifies events that are recurring (which is simply an attribute of the original event), parses and then creates new separate events (rows) for these recurring events. [Without this feature, the old script used to only pull the FIRST event of a recurring events.) Now, for recurring events with no specified end date, the job creates copies as new events for up to 12 months into the future from the Day that the job runs based on the recurrence logic of the original event (e.g. every 3rd Thursday of the Month). There is also an attribute called "Recurrence" created that describes the recurrence logic in human readable phrase for reference in the dataset.

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
