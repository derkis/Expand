class Array
	
	def include?(object = nil, &block)
		if(block)
			puts "using block -- object #{not object.nil?}"
			!!self.index(&block)
		else
			puts "calling super -- block #{not block.nil?}"
			super(object)
		end
		# return false if self.each do |item|
		# 	return true if yield(item)
		# end
	end

end

arr = [1,2,3]

puts(arr.include?(2))
puts(arr.include?(5))

puts(arr.include? do |item|
	item == 2
end)
puts(arr.include? do |item|
	item == 5
end)

puts(arr.include?(2) do |item|
	item == 5
end)

puts(arr.include?(5) do |item|
	item == 2
end)