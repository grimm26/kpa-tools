module KPA
  class Manage
    require 'fileutils'

    WORKING_DIR = "/tmp/_kpa.#{$$}"
    attr_reader :kpabackup
    def initialize(kpabackup=ARGF.filename)
      @kpabackup = kpabackup
      verify or fail "Did supply a kpabackup name?"
      expand_tarball
    end

    def dedupe_rigs
      find_dupes.each {|f| File.unlink(f)}
      mk_new_tar
      cleanup
      ensure
        cleanup
    end

    private
    def new_kpabackup_name
      kpabackup.gsub(/\s+/,'_').insert(-11,'-updated')
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
              to_be_deleted << rigs[match['name']]['path']
              rigs[match['name']] = { 'ts' => rig_timestamp, 'path' => file_path }
            end
          else
            rigs[match['name']] = { 'ts' => rig_timestamp, 'path' => file_path }
          end
        end
      end
      return to_be_deleted unless to_be_deleted.empty?
      raise "No dupes detected."
    end

    def mk_new_tar
      system "tar -C #{WORKING_DIR} -cf #{new_kpabackup_name} ."
      puts "New backup file created with duplicates removed: #{new_kpabackup_name}"
    end

    def cleanup
      FileUtils.rm_rf(WORKING_DIR)
    end
  end
end
