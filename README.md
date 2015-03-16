# kpa-tools
Some tools/scripts that I have written to use with the Kemper Profiler

## kpa_rig_dedupe.rb
This tool requires [Ruby](http://www.ruby-lang.org).  If you are on a Mac (OSX), then
you already have ruby installed and this will work.  If you are running Linux, you
probably also have ruby already or can easily install it.  If you are on Windows,
this might work if you have ruby installed and a tar executable.

I wrote this script because I wanted to removed duplicated rigs after importing
all rigs after a firmware update.  I wanted to just keep the updated versions of rigs.
I start with the procedure described via a [doc presented on the forum](http://www.kemper-amps.com/forum/index.php/Thread/5596-Managing-Rigs-Presets-and-Performances-revised-Dec-2014/).
You should follow that, but for the part where manipulation of the files comes into play,
use this script.

```
% kpa_rig_dedupe.rb 2015-03-15\ 16-51-07\ -\ Some\ Dude.kpabackup
"1962 Electro - 2015-02-13 20-57-39.kipr" is newer. Deleting "1962 Electro - 2014-07-03 16-35-18.kipr"
"AC Clean - R121 - 2015-02-13 20-57-39.kipr" is newer. Deleting "AC Clean - R121 - 2014-07-03 14-49-41.kipr"
....
"Zo-Di-Yak Cranked - 2015-02-13 20-57-39.kipr" is newer. Deleting "Zo-Di-Yak Cranked - 2014-07-02 17-43-39.kipr"
"Zo-Di-Yak Crunch 2 - 2015-02-13 20-57-39.kipr" is newer. Deleting "Zo-Di-Yak Crunch 2 - 2014-07-02 17-46-42.kipr"
New backup file created with duplicates removed: DeDupedRigs.kpabackup
 % ls -l *.kpabackup
 -rwxr-xr-x  1 dude  staff  4276736 Mar 15 16:57 2015-03-15 16-51-07 - Some Dude.kpabackup*
 -rw-r--r--  1 dude  staff  2833408 Mar 15 23:11 DeDupedRigs.kpabackup
```

The backup file DeDupedRigs.kpabackup is the one that you restore into your KPA.
