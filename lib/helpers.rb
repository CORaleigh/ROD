#helpers.rb

require 'tzinfo'

class Hash
  def rewrite mapping    #rename hash keys
    mapping.inject(self) do |memo,(oldkey,newkey)|
    	memo[newkey] = memo[oldkey]
    	memo.delete(oldkey) 
    	memo
  	end
	self
  end
end




 
  def hm(seconds) #converts seconds to hours and minutes
   Time.at(seconds).utc.strftime("%H:%M")
  end
  
  def date_fixer(odddate)   #fix m311 timestamp from milliseconds from jan 1 1970 to real date-time and adjust for time zone (-4 hours)
    x= odddate.gsub(/[^0-9]/,"") 
    timestamp = DateTime.strptime(x, '%s')
    tz = TZInfo::Timezone.get('America/New_York')
    local = tz.utc_to_local(timestamp)
    local.strftime("%m/%d/%Y %I:%M %p")
    
  end

 
