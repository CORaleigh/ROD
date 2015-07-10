

The parking folder contains scripts for creating, updating and pushing parking space data managed by 
Duncan Solutions. Monday through friday starting at 7:30am and ending at 5:00pm the duncanQuery.rb will 
run every 10 minutes and update the dataset on the Socrata Portal, providing near-real time parking meter info.
 
 -duncanQuery.rb: the main script initializes the sqlite database, queries the Duncan Solutions database for
  each of the 7 zones, compiles a cumulative total for amount spent per parking space, updates the data in
   the database and pushes the data up to Socrata.
   to run from command-line "ruby duncanQuery.rb"
 -logger: creates log files
 -space.log: the log file.
 -parkingseed.rb*: creates the sqlite database (parking.db) and seeds it with the space.json file.
  to run from command-line "ruby parkingseed.rb"
 -space.json: seed data used by parkingseed.rb to populate the database.
 -readme.md: this file
 -also requires lib/defaults.rb for configatron credentials - used for protection of private info such as usernames
  and passwords. Keeps secrets secret.
 -parking.db: sqlite3 database
 
Initial setup and run: 
1.bundle install -to install/update ruby gems
2.ruby parkingseed.rb  -to create and seed the database
3.ruby duncanQuery -to update the database and push to socrata

*sqlite3 must be installed on server