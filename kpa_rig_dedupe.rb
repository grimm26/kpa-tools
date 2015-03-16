#!/usr/bin/env ruby
#
#
# This script will take a kpabackup file (a tarball), remove duplicate rigs 
# (rigs that have the same name but different date), and tar what's left into a 
# new kpabackup file.
# I use this on OSX (Mac), it should also work on Linux.  I have not nor will I test on
# MS Windows, so you are on your own to try it.  You won't break anything by trying it :).
#
require 'fileutils'

def verify(file)
  File.exist?(file) && File.writable?(File.dirname(WORKING_DIR)) && Dir.mkdir(WORKING_DIR)
end

def get_rig_ts (m)
  Time.new(m['year'], m['month'], m['day'], m['hour'], m['min'], m['sec'])
end

def expand_tarball(file)
  system "tar -C #{WORKING_DIR} -xf '#{file}'"
end

def find_dupes
  rigs = {}
  to_be_deleted = []
  rig_regex = Regexp.new('^(?<name>.+) - (?<year>\d+)-(?<month>\d+)-(?<day>\d+) (?<hour>\d+)-(?<min>\d+)-(?<sec>\d+)\.kipr$')
  Dir.foreach(File.join(WORKING_DIR,'Rigs')) do |file|
    match = rig_regex.match(file)
    if match
      file_path = File.join(WORKING_DIR,'Rigs',file)
      rig_timestamp = get_rig_ts(match)
      if rigs.has_key?(match['name'])
        # duplicate found
        if rig_timestamp < rigs[match['name']]['ts']
          puts %Q!"#{file}" is older. Keeping "#{File.basename(rigs[match['name']]['path'])}"!
          to_be_deleted << file_path
        else
          puts %Q!"#{file}" is newer. Deleting "#{File.basename(rigs[match['name']]['path'])}"!
          #puts "#{match['name']} at #{rig_timestamp.asctime} is newer. Replacing #{match['name']} #{rigs[match['name']]['ts'].asctime}"
          to_be_deleted << rigs[match['name']]['path']
        end
      else
        rigs[match['name']] = { 'ts' => rig_timestamp, 'path' => file_path }
      end
    end
  end
  return to_be_deleted
end

def mk_new_tar
  system "tar -C #{WORKING_DIR} -cf #{UPDATED_TAR} ."
  puts "New backup file created with duplicates removed: #{UPDATED_TAR}"
end

def cleanup
  FileUtils.rm_rf(WORKING_DIR)
end

begin
WORKING_DIR = "/tmp/dedupe_kemper.#{$$}"
UPDATED_TAR = 'DeDupedRigs.kpabackup'
tarball = ARGF.filename

if verify(tarball)
  expand_tarball(tarball)
else
  puts "Did you supply a backup filename?"
  exit
end

find_dupes.each {|f| File.unlink(f)}
mk_new_tar
cleanup
ensure
  cleanup
end
