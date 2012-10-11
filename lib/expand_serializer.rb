module ExpandSerializer

	def build_json(options = {})
		methods_with_arguments = Array.new
		options[:methods].delete_if do |method|
			methods_with_arguments.push(method) if method.is_a?(Hash)
		end

		self.to_json(options).tap do |json|
			if(methods_with_arguments.length > 0)
				method_results = Hash.new
				methods_with_arguments.each do |method|
					method_symbol = method[:name]
					method_results[method_symbol] = self.send(method_symbol, *method[:arguments])
				end
				json = json.insert(-2, ",#{method_results.to_json[1..-2]}")
			end
		end
	end

end