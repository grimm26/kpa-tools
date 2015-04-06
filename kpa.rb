#!/usr/bin/env ruby
#
#
# This script will take a kpabackup file (a tarball), remove duplicate rigs 
# (rigs that have the same name but different date), and tar what's left into a 
# new kpabackup file.
# I use this on OSX (Mac), it should also work on Linux.  I have not nor will I test on
# MS Windows, so you are on your own to try it.  You won't break anything by trying it :).
#

module KPA
  class Manage
    require 'fileutils'

    WORKING_DIR = "/tmp/_kpa.#{$$}"
    attr_reader :kpabackup, :midi
    def initialize(kpabackup=ARGF.filename)
      @kpabackup = kpabackup
      @midi = { nums: {}, rigs: {} }
      @rigs = {}
      verify or fail "Did you supply a kpabackup name?"
      expand_tarball
      load_midi_assignments
      read_rigs
    end

    def finish
      mk_new_tar
      file_cleanup
      ensure
        file_cleanup
    end

    def dedupe_rigs
      remove_rig_dupes
    end

    def clean_midi_assignments
      fail "No midi data loaded." if @midi[:nums].empty?
      @midi[:nums].each do |mnum,info|
        unless File.exist?(File.join(WORKING_DIR,'Rigs',info[:rig_file]))
          if rig_exists?(info[:rig_name])
            # must be a different date of same rig
            set_midi_num_path(num: mnum, rig_file: @rigs[info[:rig_name]][0][:path])
          else
            # Warn?
            puts "Could not find rig #{info[:rig_name]} for MIDI program number #{mnum}"
            @midi[:nums].delete(mnum)
          end
        end
      end
=begin
      @rigs.each do |name,info|
        get_rig_midi_nums(name).each do |midi_num|
          set_midi_num_path(num: midi_num, rig_file: File.basename(file_path))
        end
      end
=end
      write_midi_assignments
    end

    private
    def rig_exists?(rigname)
      @rigs.has_key?(rigname)
    end

    # I should use nokogiri for this, but that seems overkill since the XML for this is very simple
    # and does not deviate.  Plus, having nokogiri as a dependency is a PITA.
    def load_midi_assignments
      File.open(File.join(WORKING_DIR,'MIDIAssignments.xml')) do |file|
        slot_re = Regexp.new('^\s*<slot num="(?<num>\d+)" name="(?<name>.+)">{DOCUMENTS}/KemperAmp/Rigs/(?<rig_file>\k<name> - (?<year>\d+)-(?<month>\d+)-(?<day>\d+) (?<hour>\d+)-(?<min>\d+)-(?<sec>\d+)\.kipr)</slot>\s*$')
        while line = file.gets
          # <slot num="5" name="Alright">{DOCUMENTS}/KemperAmp/Rigs/Alright - 2014-07-03 15-21-10.kipr</slot>
          match = slot_re.match(line)
          if match
            @midi[:nums][match['num']] = {
              rig_file: match['rig_file'],
              ts: get_rig_ts(match),
              rig_name: match['name']
            }
            if midi_has_rig?(match['name'])
              @midi[:rigs][match['name']][:midi_num] << match['num']
            else
              @midi[:rigs][match['name']] = {
                rig_file: match['rig_file'],
                ts: get_rig_ts(match),
                midi_num: [match['num']]
              }
            end
          end
        end
      end
    end

    def write_midi_assignments
      File.open(File.join(WORKING_DIR,'MIDIAssignments.xml'), "w") do |file| 
        file.puts '<?xml version="1.0" encoding="iso-8859-1"?>'
        file.puts '<programs>'
        @midi[:nums].each do |mnum,rig|
          file.puts %Q! <slot num="#{mnum}" name="#{rig[:rig_name]}">{DOCUMENTS}/KemperAmp/Rigs/#{File.basename(rig[:rig_file])}</slot>!
        end
        file.puts '</programs>'
      end
    end

    def new_kpabackup_name
      kpabackup.gsub(/\s+/,'_').insert(-11,'-updated')
    end

    def kpabackup_dir
      File.expand_path(File.dirname(kpabackup))
    end

    def verify
      File.exist?(kpabackup) && File.writable?(File.dirname(WORKING_DIR)) && Dir.mkdir(WORKING_DIR)
    end

    def get_rig_ts (m)
      Time.new(m['year'], m['month'], m['day'], m['hour'], m['min'], m['sec'])
    end

    def expand_tarball
      system "tar -C #{WORKING_DIR} -xf '#{kpabackup}'"
    end

    def midi_has_rig?(rigname=nil)
      @midi[:rigs].has_key?(rigname)
    end

    def get_rig_midi_nums(rigname=nil)
      @midi[:rigs][match['name']][:midi_num]
    end

    def set_midi_num_path(num: nil, rig_file: nil)
      @midi[:nums][num][:rig_file] = rig_file
    end

    def read_rigs
      rig_regex = Regexp.new('^(?<name>.+) - (?<year>\d+)-(?<month>\d+)-(?<day>\d+) (?<hour>\d+)-(?<min>\d+)-(?<sec>\d+)\.kipr$')
      Dir.foreach(File.join(WORKING_DIR,'Rigs')) do |file|
        match = rig_regex.match(file)
        if match
          file_path = File.join(WORKING_DIR,'Rigs',file)
          rig_timestamp = get_rig_ts(match)
          if @rigs.has_key?(match['name'])
            # duplicate found
            @rigs[match['name']].unshift({ ts: rig_timestamp, path: file_path })
          else
            @rigs[match['name']] = [{ ts: rig_timestamp, path: file_path }]
          end
        end
      end
      sort_rigs
    end

    def sort_rigs
      @rigs.each do |name,list|
        list.sort!{ |a,b| b[:ts] <=> a[:ts] }
      end
    end

    def remove_rig_dupes
      @rigs.each do |rig_name, rig_list|
        if rig_list.length > 1
          # duplicate found
          rig_list[1..rig_list.length].each do |dupe_rig|
            puts %Q!Deleting duplicate rig "#{File.basename(dupe_rig[:path])}"!
            File.unlink(dupe_rig[:path])
            @rigs[rig_name].delete(dupe_rig)
          end
        end
      end
    end

    def mk_new_tar
      system "cd #{WORKING_DIR} && COPYFILE_DISABLE=1 tar -cf #{File.join(kpabackup_dir,new_kpabackup_name)} * .??*"
      puts "New kpabackup file created with modifications: #{new_kpabackup_name}"
    end

    def file_cleanup
      FileUtils.rm_rf(WORKING_DIR)
    end
  end
end

## MAIN ##

require 'optparse'
require 'ostruct'

options = OpenStruct.new(
  dedupe_rigs: false,
  clean_midi_assignments: false,
  kpabackup: nil

)

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  opts.on('-f KPABACKUP', '--file', 'kpabackup file.') do |file|
    if File.readable?(file)
      options.kpabackup = file
    else
      opts.abort "Supplied kpabackup file, #{file}, is not readable."
    end
  end

  opts.on('--dedupe-rigs') do |tf|
    options.dedupe_rigs = tf
  end

  opts.on('--clean-midi-assignments') do |tf|
    options.clean_midi_assignments = tf
  end
end
begin
  optparse.parse!
rescue SystemExit
  abort
rescue OptionParser::ParseError => e
  optparse.abort "#{e.message}\n\n#{optparse.help}"
end

if options.kpabackup.nil?
  options.kpabackup = ARGF.filename
end

kpa = KPA::Manage.new(ARGF.filename)

kpa.dedupe_rigs if options.dedupe_rigs
kpa.clean_midi_assignments if options.clean_midi_assignments
kpa.finish
