#!/usr/bin/env ruby

#
# Mailbox converter
#
# This script converts folders of emlx files back into the mbox
# format used by Mac OS X Mail before 10.4.
#
# The script needs to be provided with a source directory on the
# command line, and it can optionally be provided with a destination
# directory as well.  By default, it will save the mbox files in a
# folder named "Converted".  Once converted, the files can be
# imported back into a previous version of the mail client by
# choosing File > Import Mailboxes > Other.
# 
# Thanks to Léonard Bouchet for improving the mail header support
# to work with tabs as well as spaces.
# 
# Author::   Marshall Elfstrand (mailto:marshall@vengefulcow.com)
# Version::  1.2
#

# require "ftools"
require "date"

#
# Class that converts folders of emlx files to emlx format.
#
class EmlxConverter

  attr_reader :success_count   # Number of messages converted
  attr_reader :warning_count   # Number of messages had warnings
  attr_reader :error_count     # Number of messages not converted

  #
  # Initializes the converter count values.
  #
  def initialize
    @success_count = 0
    @warning_count = 0
    @error_count = 0
  end #def

  #
  # Searches the given directory for all mbox directories and processes
  # each one.
  #
  # +sourceDir+ is a directory containing ".mbox" directories.
  # +destDir+ is the directory in which the converted files will be placed.
  #
  def convert_mailboxes(source_dir, dest_dir)
    source_dir = File.expand_path(source_dir)
    @source_root = (File.dirname(source_dir) + "/") if @source_root.nil?
    puts "Processing " + source_dir[@source_root.size..-1] + "..."
  
    # Compile messages in mbox directories.
    mbox_dirs = Dir.entries(source_dir).find_all do |entry|
      File.directory?("#{source_dir}/#{entry}") and
      (entry[-5..-1] == ".mbox")
    end #find_all
    mbox_dirs.each do |dir|
      if File.directory?("#{source_dir}/#{dir}/Messages")
        self.compile_messages("#{source_dir}/#{dir}", dest_dir)
      end #if
    end #each
  
    # Recursively process sub-directories.
    subdirs = Dir.entries(source_dir).find_all do |entry|
      File.directory?("#{source_dir}/#{entry}") and
      entry[0, 1] != "." and
      entry[-5..-1] != ".mbox"
    end #do
    subdirs.each do |dir|
      self.convert_mailboxes("#{source_dir}/#{dir}", "#{dest_dir}/#{dir}")
    end #each
    
  end #def

  #
  # Finds all messages in the given mbox directory and compiles
  # them into a single mbox file.
  #
  # +sourceDir+ is a directory containing a "Messages" directory.
  # +destDir+ is the directory where the single mbox file will be placed.
  #
  def compile_messages(source_dir, dest_dir)

    # Find emlx files in the "Messages" subdirectory and prepend
    # the full path to each file name.
    files = Dir.entries("#{source_dir}/Messages").find_all do |entry|
      entry[-5..-1] == ".emlx"
    end #find_all
    files.collect! { |file| "#{source_dir}/Messages/#{file}" }
  
    # Create destination directory if necessary.
    if not File.exists?(dest_dir)
      begin
        Dir.mkdir(dest_dir)
      rescue
        puts "  ** Error creating #{dest_dir}: " + $!.to_s
        puts "  ** #{files.size} messages are being skipped."
        @error_count += files.size
        return
      end
    elsif not File.directory?(dest_dir)
      puts "  ** Error creating #{dest_dir}: File exists"
      puts "  ** #{files.size} messages are being skipped."
      @error_count += files.size
      return
    end #if
  
    # Write each file to the mbox file.
    mboxname = File.basename(source_dir, ".mbox") + "-mbox"
    puts "  Building #{mboxname} (#{files.size} messages)..."
    File.open("#{dest_dir}/#{mboxname}", "w") do |outfile|
      files.each do |file|
        begin

          # Write out the "From" header.
          outfile.puts self.extract_header(file)
      
          # Read the number of bytes from the first line of the input
          # file, and then copy that many bytes to the output file.
          File.open(file, "r") do |infile|
            bytes_remaining = infile.gets.to_i
            while (bytes_remaining > 0)
              buffer_size = [2048, bytes_remaining].min  # 2K max buffer
              outfile.write(infile.read(buffer_size))
              bytes_remaining -= buffer_size
            end #while
          end #open
      
          # Write out an extra two lines to ensure proper separation.
          outfile.write "\n\n"
          @success_count += 1
      
        rescue
          file_local = file[@source_root.size..-1]
          puts "  ** Error converting #{file_local}: " + $!.to_s
          @error_count += 1
        end
      end #each
    end #open

  end #def

  #
  # Creates the standard mbox "From " header based on fields in the emlx file.
  #
  # +file+ is the emlx file from which the fields will be read.
  #
  # Returns the "From " header as a string.
  #
  def extract_header(file)

    # Find "From" and "Date" fields in the file.
    address = ""
    date = ""
    received = ""
    has_warning = false
    file_local = file[@source_root.size..-1]
    File.open(file, "r") do |infile|
      current_line = infile.gets
      while ((address == "") or (date == "")) and (current_line != nil)
        first_six_chars = current_line[0..5].downcase
        if /^from:\s/.match(first_six_chars)
          address = current_line[6..-1].strip
        elsif /^date:\s/.match(first_six_chars)
          date = current_line[6..-1].strip
        end #if
        current_line = infile.gets
      end #while
    end #open
  
    # Make sure address field was found.
    if address == ""
      puts "  ** Using EMLX-2-MBOX for missing 'From' field in " + file_local
      address = "EMLX-2-MBOX"
      has_warning = true
    else

      # Extract address from "From" field if necessary.
      address.scan(/.* <(.*@.*)>/) { |match| address = match[0].strip }

      # Filter out some weird address prefixes.
      address = address[5..-1] if address[0..4].downcase == "smtp:"
      address = address[7..-1] if address[0..6].downcase == "mailto:"

    end #if

    # Make sure date field was found.
    if date == ""
      puts "  ** Using current date for missing 'Date' field in " +
           file_local
      date = Time.now.asctime
      has_warning = true
    else
      # Convert date to asctime format.
      begin
        date = Date.rfc2822(date).asctime
      rescue
        puts "  ** -> Using current date for invalid 'Date' field in " +
          file_local + " " + $!.to_s
        date = Time.now.asctime
      end
    end #if

    @warning_count += 1 if has_warning
    return "From #{address} #{date}"

  end #def

  #
  # Writes out a summary of the conversion.
  #
  def print_summary()
    field_len = [@success_count, @warning_count, @error_count].max.to_s.size
    puts ""
    puts "    %s messages were converted" %
         @success_count.to_s.rjust(field_len)
    puts "    %s of those had warnings" %
         @warning_count.to_s.rjust(field_len)
    puts "    %s messages could not be converted" %
         @error_count.to_s.rjust(field_len)
    puts ""
  end #def

  #
  # Reads command-line arguments and calls the processing routines.
  #
  def self.main(args)
    if args.size > 0
      source_path = args[0]
      source_path = source_path[0..-2] if source_path[-1, 1] == "/"
      dest_path = "Converted"
      dest_path = args[1] if args.size > 1
      dest_path = dest_path[0..-2] if dest_path[-1, 1] == "/"
      converter = EmlxConverter.new
      converter.convert_mailboxes(source_path, dest_path)
      converter.print_summary
    else
      puts "Usage:  emlx2mbox.rb /path/to/source [/path/to/dest]"
    end #if
  end #def

end #class


# Call main() if running from the command line.
EmlxConverter.main(ARGV) if $0 == __FILE__
