class Array

	def include?(object = nil, &block)
		if(block)
			!!self.index(&block)
		else
			super(object)
		end
	end

	def object_passing_test
		return nil if self.each do |item|
			return item if yield(item)
		end
	end

end