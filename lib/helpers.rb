#helpers.rb

class Hash
  def rewrite mapping
    mapping.inject(self) do |memo,(oldkey,newkey)|
    	memo[newkey] = memo[oldkey]
    	memo.delete(oldkey) 
    	memo
  	end
	self
  end
end




 
  def hm(seconds)
   Time.at(seconds).utc.strftime("%H:%M")
  end
  
  def date_fixer(odddate)   #fix m311 timestamp from milliseconds from jan 1 1970 to real date-time and adjust for time zone (-4 hours)
    x= odddate.gsub(/[^0-9]/,"") 
    (DateTime.strptime(x, '%Q')-4.hours).strftime("%m/%d/%Y %I:%M %p")
    
  end

 
