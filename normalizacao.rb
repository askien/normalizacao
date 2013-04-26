#!/usr/bin/ruby
# encoding: UTF-8
DIACRITIC_CHARS = "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž"
REGULAR_CHARS = "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
# Returns an array of directories to process
def mock_get_file_list
	directory_list = Array.new
	contents = File.read("../tudo.txt")
	contents.each_line do |line|
		if line =~/Pasta de/
			line = line.slice(33..-1)
			if File::ALT_SEPARATOR!=nil && line.count(File::ALT_SEPARATOR) > line.count(File::SEPARATOR) 
				line.gsub!(File::ALT_SEPARATOR,File::SEPARATOR)
			end
			directory_list << line if line.size > 2
			#puts line
		end
	end
	return directory_list
end

def get_file_list(base_path)
	file_list = Dir[[base_path,"**/*"].join(File::SEPARATOR)]
	return file_list.map {|filename| File.directory?(filename) ? filename : nil}.compact.map {|filename| filename[base_path.size+1..-1] }
end

# Seperate directories by depth
def seperate_directories_by_depth(directory_list)
	hierarchical_directory_list = Array.new
	directory_list.each do |line|
		chunks = line.split(File::SEPARATOR)
		number_of_chunks = chunks.count
		unless hierarchical_directory_list[number_of_chunks]
			hierarchical_directory_list[number_of_chunks-1] = Array.new
		end
		hierarchical_directory_list[number_of_chunks-1] << line
	end
	return hierarchical_directory_list
end

def normalize(hierarchical_directory_list, mode_of_operation=nil)
	# Now we normalize starting by the leaves of the tree, working towards the trunk
	hierarchical_directory_list.reverse_each do |nivel|
		nivel.each do |filename|
			original_filename = filename.encode("UTF-8");
			# Skip works in progress
			if original_filename =~/digicol lacunas/
				next
			end
			original_filename.chomp!
			chunks = original_filename.split(File::SEPARATOR)
			last_chunk = chunks.last
			without_last_chunk = chunks.clone
			without_last_chunk.delete_at(-1)
			rebuilt_filename = without_last_chunk.join(File::SEPARATOR)
			working_filename = last_chunk
			working_filename = working_filename.downcase.gsub(/()*\(()*/,"-").gsub(/()*\)()*/,"").gsub(/( )*\-( )*/,"-").gsub(/ /,"_").gsub(/&/,"e").tr(DIACRITIC_CHARS,REGULAR_CHARS)
			# special case for date
			if working_filename =~/.*?\d{2}.*?\d{2}.*?\d{4}.*?/
				working_filename = working_filename.tr(" _.-","")
				#disabled. Do not fix dates
				#working_filename = working_filename[4..7]+working_filename[2..3]+working_filename[0..1]
			end
			#Treat special edge case where we were adding seperators on top level directories, ie: globo -> /globo
			final_filename = rebuilt_filename.empty? ? working_filename : [rebuilt_filename,working_filename].join(File::SEPARATOR) 
			#Skip if no change
			#if final_filename.casecmp(original_filename)==0
			#	next
			#end
			command = "mv -i \"#{original_filename}\" \"#{final_filename}\"" 
			if mode_of_operation=="print"
				puts command
			elsif mode_of_operation=="execute"
				system(command)
			end
		end
	end
end

def print_usage
		puts "normalizacao [comando]"
		puts ""
		puts "Comandos:"
		puts "listar - Escreve na tela os comandos que renomeiam dos directórios do acervo"
		puts "Exemplo:"
		puts "  normalizacao listar > comandos.sh"
		puts ""
		puts "executar - Executa os comandos que renomeiam os directórios do acervo"
		puts "Exemplo:"
		puts "  normalizacao executar"
end

def process_arguments
	if ARGV.count==0 || ARGV.count>1
		return "help"
	end
	if ARGV.count==1
		if ARGV[0]=="listar"
			return "print"
		elsif ARGV[0]=="executar"
			return "execute"
		else
			return "help"
		end
	end
end

def main
	operation = process_arguments
	if operation=="help"
		print_usage
		return
	end
	#directory_list = get_file_list("e:/acervo")
	directory_list = mock_get_file_list
	hierarchical_directory_list = seperate_directories_by_depth(directory_list)
	normalize(hierarchical_directory_list,operation)
end

main