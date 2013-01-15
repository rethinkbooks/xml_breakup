#!/Users/lance/.rvm/rubies/ruby-1.9.3-p362/bin/ruby

require 'rubygems'
require 'libxml'
require 'fileutils'

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
files = get_all_files directory
files.each do |file|
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

def get_all_files (dir)
	#Dir.entries(dir).sort_by{|c| File.stat(c).ctime}
	files = []
	Dir.entries(dir).sort_by{|c| File.stat("#{dir}/#{c}").ctime}.each do |f|
		next unless f =~ /xml$/
		files << f
	end
	return files
end

def smallify (dir, file)
	filename = "#{dir}/#{file}"
	reader = XML::Reader.file(filename)
	header = find_header(filename)
	count = 1
	run = true

	if File.size(filename) < FILESIZE then
		#FileUtils.touch(filename)
		puts "Skipping: #{filename}"
		sleep 1
		return
	end

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
