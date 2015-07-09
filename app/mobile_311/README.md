### Mobile311
##### Description 
 Raleigh solid waste services uses the [Mobile311](https://map.mobile311.com/Mobile311/Login.aspx?ReturnUrl=%2fMobile311%2fdefault.aspx) web application in the field to track solid waste infractions (EG trash bin left out). The user runs a report on Mobile311's website, downloads it to an Excel file and manually looks up the property owners address to mail out warnings. These scripts use Mobile_311's API to get the issues, transform the fields, look up the property owner's name & address from the [ArcGIS REST Services Directory](http://maps.raleighnc.gov/arcgis/rest/services/Parcels/MapServer/exts/PropertySOE/RealEstateSearch) and pushes the results to two datasets - one on [Raleigh's open data portal](https://data.raleighnc.gov/) the other on a [private Socrata portal](https://corecon.demo.socrata.com) where internal data can be shared.  
##### Links  
[Mobile311 data set on Socrata @Raleigh](https://data.raleighnc.gov/Government/Solid-Waste-Services-Code-Violations-Mobile-311-/h5i3-8nha)  
[Mobile311 data set on Socrata @Corecon](https://corecon.demo.socrata.com/dataset/Solid-Waste-Services-Code-Violations-Mobile-311/2uyt-2iv6)  
[Instructions for Basic Integration, Mobile311 API v.2.0.pdf](/docs/Instructions for Basic Integration, Mobile311 API v.2.0.pdf)
##### Files
##### [m311.rb](m311.rb) - Runs hourly between 8am and 4pm Monday thru Friday
 
  - initialize  - sets up soda clients (2)  and global variables
  - get_token  - gets token from Mobile311
  - get data  - gets new/updated data from Mobile311 via API, modifies the new data (fixes dates, renames hash keys, removes extraneous data, adds delete key for objects that should be deleted from Socrata, adds additional fields & packages it up for export)
  - lookup - normalizes address fields, removes unwanted characters and posts  it to ArcGIS REST Service to get property owners name and address
  - export - posts data to Raleigh and Corecon data sets & logs Socrata response    

>To run manually: cd app/mobile311 - must be on OakTree or connected via VPN  
 _ruby m311.rb_
##### [rebuid_archive.rb](rebuild_archive.rb) - Use to rebuild entire archive from scratch  

  - initialize  - sets up soda client for Socrata on Raleigh
  - get_token  - gets token from Mobile311
  - get data  - sets up loop to poll Mobile311 for all data 30 days at a time starting with the beginning of mobile311 data gathering. The _@time_ and _@time2_ variables should be set to # of days since Raleigh started gathering data with Mobile311 and -30 respectively. The # of loops should also be set respective to the number of 30 day periods between start and the current date. The script then gets new/updated data from Mobile311 via API, modifies the new data (fixes dates, renames hash keys, removes extraneous data, adds delete key for objects that should be deleted from Socrata, adds additional fields & packages it up for export)
  - lookup - normalizes address fields, removes unwanted characters and posts  it to ArcGIS REST Service to get property owners name and address and adds the new data to the set
  - export - posts data to Raleigh data sets & logs Socrata response   
   
>To run manually: cd app/mobile311 - must be on OakTree or connected via VPN  
 _ruby rebuild\_archive.rb_  
        
       



