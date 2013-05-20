#!/usr/bin/ruby
# encoding: UTF-8

require 'Set'

directory_list = Dir["**/*"]
character_list = Set.new
offenders = Hash.new
directory_list.each do |filename|
	#next unless File.directory?(filename)

	# handle set
	character_list.merge(File.basename(filename).chars)

	# handle first offenders
	File.basename(filename).each_char do |c|
		if c =~ /[a-zA-Z0-9_-]/
			offenders["a a z, A a Z, 0 a 9, _ e -"] = filename unless offenders["a a z, A a Z, 0 a 9, _ e -"]
		elsif !offenders[c]
			offenders[c] = Array.new
			offenders[c] << filename
		else
			offenders[c] << filename			
		end
	end
end

puts "Lista de caracteres"
character_list.each do |x|
	print x
end
puts "linha"

puts "Lista de offenders"
offenders.keys.each do |c|
	if offenders[c].class == String
		puts "#{c} --> #{offenders[c]}"
	else
		puts "#{c} -->"
		offenders[c].each do |f|
			puts f
		end
	end
end