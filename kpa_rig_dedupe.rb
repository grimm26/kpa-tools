#!/usr/bin/env ruby
#
#
# This script will take a kpabackup file (a tarball), remove duplicate rigs 
# (rigs that have the same name but different date), and tar what's left into a 
# new kpabackup file.
# I use this on OSX (Mac), it should also work on Linux.  I have not nor will I test on
# MS Windows, so you are on your own to try it.  You won't break anything by trying it :).
#
require_relative 'kpa'

kpa = KPA::Manage.new(ARGF.filename)

kpa.dedupe_rigs
