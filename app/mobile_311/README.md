### Mobile311
##### Description 
 Raleigh solid waste services uses the [Mobile311](https://map.mobile311.com/Mobile311/Login.aspx?ReturnUrl=%2fMobile311%2fdefault.aspx) web application in the field to track solid waste infractions (EG trash bin left out). The user runs a report on Mobile311's website, downloads it to an Excel file and manually looks up the property owners address to mail out warnings. These scripts use Mobile_311's API to get the issues, transform the fields, look up the property owner's name & address from the [ArcGIS REST Services Directory](http://maps.raleighnc.gov/arcgis/rest/services/Parcels/MapServer/exts/PropertySOE/RealEstateSearch) and pushes the results to two datasets - one on [Raleigh's open data portal](https://data.raleighnc.gov/) the other on a [private Socrata portal](https://corecon.demo.socrata.com) where internal data can be shared.  
##### Links  
[Mobile311 data set on Socrata @Raleigh](https://data.raleighnc.gov/Government/Solid-Waste-Services-Code-Violations-Mobile-311-/h5i3-8nha)  
[Mobile311 data set on Socrata @Corecon](https://corecon.demo.socrata.com/dataset/Solid-Waste-Services-Code-Violations-Mobile-311/2uyt-2iv6)  
[Instructions for Basic Integration, Mobile311 API v.2.0.pdf](/docs/Instructions for Basic Integration, Mobile311 API v.2.0.pdf)
##### Files
##### [m311.rb](m311.rb)
To run manually: cd app/mobile311 - must be on OakTree or connected via VPN
> _ruby m311.rb_
##### rebuid_archive.rb
To run manually: cd app/mobile311 - must be on OakTree or connected via VPN
> _ruby rebuild_archive.rb_
