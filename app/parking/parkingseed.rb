#parkingseed.rb - create and seed sqlite3 database

require 'json'
require 'crack'
require 'sqlite3'
a=0
db=SQLite3::Database.new('parking.db')
db.execute("create table Spaces (id INTEGER PRIMARY KEY, last_active TEXT, lat DECIMAL(10,6), long DECIMAL(10,6), street_name TEXT, bay_number INTEGER, zone INTEGER,
                                 rate INTEGER, time_limit INTEGER, hours TEXT, last_update TEXT, status TEXT, expires_at TEXT, cumulative_total DECIMAL(19, 2))")
pspace = Crack::JSON.parse(open("space.json").read).to_hash
 
pspace['features'].each do |seed|
  @lat = seed['geometry']['coordinates'][1]
  @long = seed['geometry']['coordinates'][0]
  @street = seed['properties']['STREET']
  @bay = seed['properties']['ID']
  @zone = seed['properties']['ID_1']
  @cost = seed['properties']['COST']
  @hours= seed['properties']['HOURS']
  @time = seed['properties']['TIME']
   db.execute("INSERT INTO SPACES (id,last_active,lat,long,street_name,bay_number, zone, rate, time_limit, hours, last_update, status, expires_at, cumulative_total)
              VALUES( NULL,last_active,?,?,?,?,?,?,?,?,NULL,NULL,NULL,0)",
              @lat, @long, @street, @bay, @zone, @cost, @hours, @time)  
 a+=1
 puts a
end

