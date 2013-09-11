#!/usr/bin/env ruby

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
  Dir.entries(dir)
    .sort_by { |c| File.stat("#{dir}/#{c}").ctime }
    .select { |f| [".xml", ".cot"].include?(File.extname(f)) }
end

def smallify (dir, file)
  filename = "#{dir}/#{file}"
  reader = XML::Reader.file(filename)
  header = find_header(filename)
  count = 1
  run = true
  fs = File::Stat.new(filename)
  year  = fs.mtime.year
  month = fs.mtime.month
  day   = fs.mtime.day
  hour  = fs.mtime.hour
  min   = fs.mtime.min
  sec   = fs.mtime.sec

  touch_string = sprintf "touch -t %04d%02d%02d%02d%02d.%02d" % [year, month, day, hour, min, sec]


  if File.size(filename) < FILESIZE then
    FileUtils.touch(filename)
    puts "Skipping: #{filename}"
    sleep 1
    return
  end

  puts "Processing: #{filename}"
  while run do
    ext = File.extname(file)
    new_file = "#{dir}/#{file}.#{count}#{ext}"
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
    system("#{touch_string} #{new_file}")
    count += 1
  end
  FileUtils.mv(filename, "#{dir}/bak/#{file}")
end



}
