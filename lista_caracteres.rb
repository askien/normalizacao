#!/usr/bin/ruby
# encoding: UTF-8

require 'Set'

directory_list = Dir["**/*"]
character_list = Set.new
first_offenders = Hash.new
directory_list.each do |filename|
	#next unless File.directory?(filename)

	# handle set
	character_list.merge(File.basename(filename).chars)

	# handle first offenders
	File.basename(filename).each_char do |c|
		if !first_offenders[c]
			first_offenders[c] = filename
		end
	end
end

puts "Lista de caracteres"
character_list.each do |x|
	print x
end
puts "linha"

puts "Lista de first offenders"
first_offenders.keys.each do |c|
	puts "#{c} --> #{first_offenders[c]}"
end