def normalize(filename)
	normalized = filename
end
def partition(filename)
	chunks = filename.split("/")
	broken = ""
	chunks.map {|c| broken.concat(c+" ")}
	return broken
end

directory_list = Dir["**/*"]

directory_list.each do |original_filename|
	if File.directory?(original_filename)
		puts original_filename
		puts partition(original_filename)
		puts original_filename.encoding
	end
end

