##### /app/permit_up.rb/test_permit_up.rb
> This is for the automation of updating the City of Raleigh Building Permits data-set on Socrata.
> All new permit data from the past two days will be uploaded to Socrata's open data portal for the city of Raleigh.
> It should be run via a cron job on a daily basis.
> To run manually: ruby permit_up.rb from this files directory.
 
##### /app/permit_chunk.rb/test_permit_chunk.rb
>  This script is for bulk uploading permit data to Socrata. It is for starting a new Permit data-set or for when 
>  you need to push large (~10,000) records.
>  Run this script => ruby permit_chunk.rb followed by an integer representing the 1st permit id you want to upload.
>  EX. _ruby permit_chunk.rb 1000_  => will upload permit data with permit numbers 1000 through 11000.
>  This will query the database, concatenate the address fields, rename the column names for a more human readable table,
>  adjust the date fields and push up to 10,000 records at a time based on permit id.

##### /lib/defaults.rb
>  configatron env variables for keeping secret stuff sectret

##### /lib/helpers.rb
>  helper methods for renameing hash keys
 
##### /lib/permit_headers.css
>  contains hash key names for creating a new socrata data set for permits.
 
 
	


