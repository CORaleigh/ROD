#scf_make.rb - create  sqlite3 database
# see click fix api key dd06611a63f3ba3dc1e111f63611a14f542d5a70

require 'json'
require 'sqlite3'
require 'httparty' 
require 'date' 


db=SQLite3::Database.new("../../db/seeCF.db")
db.execute("CREATE TABLE Issues (id INTEGER PRIMARY KEY, issue_id INTEGER, summary TEXT, description Text, status TEXT, address TEXT, rating INTEGER, lat DECIMAL(10,6), lng DECIMAL(10,6),
            url TEXT, user_id INTEGER, created_at TEXT, updated_at TEXT, acknowledged_at TEXT, closed_at TEXT)")


@counter=1
@count=0
while @counter<=5 do
  case @counter
  when 1
    @results =HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=open&after=2014-01-01T01:00:00-04:00&page=1&per_page=1000").to_hash
  when 2
    @results =HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=acknowledged&after=2014-01-01T01:00:00-04:00&page=1&per_page=1000").to_hash
  when 3
    @results =HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=closed&after=2014-01-01T01:00:00-04:00&page=1&per_page=1000").to_hash
  when 4   
    @results =HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=archived&after=2014-01-01T01:00:00-04:00&page=1&per_page=1000").to_hash
    when 5
  @results =HTTParty.get("https://seeclickfix.com/api/v2/issues.json?place_url=raleigh&status=archived&after=2014-01-01T01:00:00-04:00&page=2&per_page=1000").to_hash
  end
     puts @results.size.to_s + " count"
     @results['issues'].each do |a|
       @issue_id = a["id"]
       @summary = a["summary"]
       @description = a["description"]
       @status = a["status"]       
       @address = a["address"]
       @rating = a["rating"]
       @lat = a["lat"]
       @lng = a["lng"]
       @url = a["url"]
       @user_id = a["reporter"]["id"]
       @created_at = a["created_at"]
       @updated_at = a["updated_at"]
       @acknowledged_at = a["acknowledged_at"]
       @closed_at = a["closed_at"]

 db.execute("INSERT INTO ISSUES ( id, issue_id, summary, status, description, address, rating, lat, lng,
               url, user_id, created_at, updated_at, acknowledged_at, closed_at)
               VALUES(NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
               @issue_id, @summary, @status, @description, @address, @rating, @lat, @lng, @url, @user_id, @created_at, @updated_at, @acknowledged_at, @closed_at)
       puts @count
       @count+=1
     end
 @counter+=1

end
