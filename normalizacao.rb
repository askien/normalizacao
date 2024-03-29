#!/usr/bin/ruby
# encoding: UTF-8
DIACRITIC_CHARS = "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž"
REGULAR_CHARS = "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
$log_file = nil
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
		unless hierarchical_directory_list[number_of_chunks-1]
			hierarchical_directory_list[number_of_chunks-1] = Array.new
		end
		hierarchical_directory_list[number_of_chunks-1] << line
	end
	return hierarchical_directory_list
end

def normalize(hierarchical_directory_list,base_directory,mode_of_operation=nil)
	# Now we normalize starting by the leaves of the tree, working towards the trunk
	hierarchical_directory_list.reverse_each do |nivel|
		nivel.each do |filename|
			original_filename = filename.encode("UTF-8");
			# Skip works in progress
			# Not skipping lacunas
			#if original_filename =~/lacunas/
			#	$log_file.puts("Saltando #{[base_directory,original_filename].join(File::SEPARATOR)}") if $log_file
			#	next
			#end
			original_filename.chomp!
			working_filename = File.basename(original_filename)
			working_filename = working_filename.downcase.gsub(/()*\(()*/,"-").gsub(/()*\)()*/,"").gsub(/( )*\-( )*/,"-").gsub(/ /,"_").gsub(/&/,"e").tr(DIACRITIC_CHARS,REGULAR_CHARS)
			# special case for date
			if working_filename =~/.*?\d{2}.*?\d{2}.*?\d{4}.*?/
				working_filename = working_filename.tr(" _.-","")
				#disabled. Do not fix dates
				#working_filename = working_filename[4..7]+working_filename[2..3]+working_filename[0..1]
			end
			# fix month
			if working_filename =~/^\d{2}( )*?-( )*?(janeiro|fevereiro|marco|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)/i
				working_filename = working_filename[0..1]
			end
			# fix fulldate
			if working_filename =~/^\d{8}$/
				if (working_filename[2..3]== File.basename(File.dirname(original_filename)) or working_filename[2..3]== File.basename(File.dirname(original_filename))[0..1] ) and working_filename[4..7]== File.basename(File.dirname(File.dirname(original_filename)))
					working_filename = working_filename[0..1]				
				else
					$log_file.puts("Data inconsistente -> #{[base_directory,original_filename].join(File::SEPARATOR)}") if $log_file
					next
				end
			end			
			#Treat special edge case where we were adding seperators on top level directories, ie: globo -> /globo
			#final_filename = rebuilt_filename.empty? ? working_filename : [rebuilt_filename,working_filename].join(File::SEPARATOR) 
			final_filename = working_filename
			#Skip if no change
			#puts "#{final_filename} original #{original_filename}"
			if final_filename.casecmp(File.basename(original_filename))==0
				$log_file.puts("Nada a fazer com #{[base_directory,original_filename].join(File::SEPARATOR)}") if $log_file
				next
			else
				if File.exists?([base_directory,final_filename].join(File::SEPARATOR))
					$log_file.puts("Já existe #{[base_directory,final_filename].join(File::SEPARATOR)}") if $log_file
					next
				end
				$log_file.puts("Renomeando #{[base_directory,original_filename].join(File::SEPARATOR)} para #{[base_directory,final_filename].join(File::SEPARATOR)}") if $log_file
			end

			#UNIX
			#command = "mv -i \"#{[base_directory,original_filename].join(File::SEPARATOR)}\" \"#{[base_directory,final_filename].join(File::SEPARATOR)}\"" 
			command = "ren \"#{[base_directory,original_filename].join(File::SEPARATOR)}\" \"#{working_filename}\"" 
			command.gsub!("/","\\")
			begin
				command.encode("CP850")
				#puts "Comando: #{command}"
				if mode_of_operation=="print"
					command = command.encode("CP850")
					puts command.encode("CP850")
				elsif mode_of_operation=="execute"
					puts command.encode("CP850")
					#command = command.encode("CP850")
					#puts command.encode("CP850")
					rc = system(command.encode("CP850"))
					if rc!=0
						STDERR.puts command
					end
				end
			rescue
				STDERR.puts "Erro de encoding com #{command}"
			end
		end
	end
end

def print_usage
		puts "normalizacao comando diretorio [-l log]"
		puts ""
		puts "Comandos:"
		puts "listar - Escreve na tela os comandos que renomeiam dos directórios do acervo"
		puts "Exemplo:"
		puts "  normalizacao listar . > comandos.sh"
		puts ""
		puts "executar - Executa os comandos que renomeiam os directórios do acervo"
		puts "Exemplo:"
		puts "  normalizacao executar ."
end

# TODO Refactor this nasty crap
def process_arguments
	# No arguments displays help. Mininum number of arguments is 2.
	if ARGV.count==0 || ARGV.count<2
		return "help"
	end
	if ["listar","executar"].include?(ARGV[0])
		current_param = 2
		while current_param<ARGV.count+1
			unless ARGV[current_param+1]
				current_param+=2
				next				
			end
			case ARGV[current_param]
			when "-l" then $log_file = File.open(ARGV[current_param+1],"w")
			end
			current_param+=2
		end

		if ARGV[0]=="listar"
			return "print"
		elsif ARGV[0]=="executar"
			return "execute"
		end
	else
		return "help"
	end
end

def get_base_directory
	base_directory = ARGV[1] || "."
	base_directory = base_directory.encode("UTF-8");
	base_directory = File.expand_path(base_directory)
	File.directory?(base_directory) ? base_directory : nil
end

def main
	operation = process_arguments
	if operation=="help"
		print_usage
		return
	end
	base_directory = get_base_directory()
	unless base_directory
		puts "Diretório inválido."
		return
	end

	directory_list = get_file_list(base_directory)
	$log_file.puts("Número de diretórios: #{directory_list.count}") if $log_file
	#directory_list = mock_get_file_list
	hierarchical_directory_list = seperate_directories_by_depth(directory_list)
	normalize(hierarchical_directory_list,base_directory,operation)
	$log_file.close if $log_file
end

main