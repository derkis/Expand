class Array

	def include?(object = nil, &proc)
		if(proc)
			!!self.index(&proc)
		else
			super(object)
		end
	end

end