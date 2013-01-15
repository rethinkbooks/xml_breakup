#!/Users/lance/.rvm/rubies/ruby-1.9.3-p362/bin/ruby

require 'rubygems'
require 'libxml'

include LibXML

FILESIZE = 50000000

if ARGV.size < 1 then
	puts "Target directory must be supplied."
	puts "Usage: 'smallifier <directory>'"
	exit
end


directory = ARGV[0]
	
count = 0

make_backup_directory directory
big_files = get_big_files directory
big_files.each do |file|
	smallify(directory, file)
end





BEGIN {

def find_header (file)
	top = ""
	File.open(file, "r") do |f|
		while line = f.gets
			top += line
			break if line =~ /\<\/header\>/
		end
	end
	return top
end

def make_backup_directory (dir)
	backup_dir = dir + "/bak"
	return if File.directory? backup_dir
	Dir::mkdir(backup_dir)
end

def get_big_files (dir)
	#Dir.entries(dir).sort_by{|c| File.stat(c).ctime}
	big_files = []
	Dir.entries(dir).sort_by{|c| File.stat("#{dir}/#{c}").ctime}.each do |f|
		next if File.size(f) < FILESIZE
		big_files << f
	end
	return big_files
end

def smallify (dir, file)
	filename = "#{dir}/#{file}"
	reader = XML::Reader.file(filename)
	header = find_header(filename)
	count = 1
	run = true

	puts "Processing: #{filename}"
	while run do
		new_file = "#{dir}/#{file}.#{count}.xml"
		puts "  Creating: #{new_file}"
		f = File.open(new_file, "w")
		f.write header
		while f.size < FILESIZE
			if reader.read then
				if reader.name == 'product' && reader.node_type == XML::Reader::TYPE_ELEMENT then
					f.write reader.read_outer_xml
					f.write "\n"
				end
			else
				run = nil
				break
			end
		end
		f.write("</ONIXmessage>\n")
		f.close
		count += 1
	end
	File.rename(filename, "#{dir}/bak/#{file}")
end



}
