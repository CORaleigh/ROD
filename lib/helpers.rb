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
  
  def date_fixer(odddate)
    x= odddate.gsub(/[^0-9]/,"") 
    DateTime.strptime(x, '%Q').strftime("%m/%d/%Y %I:%M %p")
    
  end


