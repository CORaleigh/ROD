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


