# kpa-tools
Some tools/scripts that I have written to use with the Kemper Profiler

## kpa.rb
This tool requires [Ruby](http://www.ruby-lang.org).  If you are on a Mac (OSX), then
you already have ruby installed and this will work.  If you are running Linux, you
probably also have ruby already or can easily install it.  If you are on Windows,
this might work if you have ruby installed and a tar executable.

I wrote this script because I wanted to removed duplicated rigs after importing
all rigs after a firmware update.  I wanted to just keep the updated versions of rigs.
I start with the procedure described via a [doc presented on the forum](http://www.kemper-amps.com/forum/index.php/Thread/5596-Managing-Rigs-Presets-and-Performances-revised-Dec-2014/).
You should follow that up to step 6, but for the part where manipulation of the files comes into play,
use this script.

<pre>
<strong>% kpa.rb --dedupe-rigs 2015-03-15\ 16-51-07\ -\ Some\ Dude.kpabackup</strong>
"1962 Electro - 2015-02-13 20-57-39.kipr" is newer. Deleting "1962 Electro - 2014-07-03 16-35-18.kipr"
"AC Clean - R121 - 2015-02-13 20-57-39.kipr" is newer. Deleting "AC Clean - R121 - 2014-07-03 14-49-41.kipr"
....
"Zo-Di-Yak Cranked - 2015-02-13 20-57-39.kipr" is newer. Deleting "Zo-Di-Yak Cranked - 2014-07-02 17-43-39.kipr"
"Zo-Di-Yak Crunch 2 - 2015-02-13 20-57-39.kipr" is newer. Deleting "Zo-Di-Yak Crunch 2 - 2014-07-02 17-46-42.kipr"
New backup file created with duplicates removed: 2015-03-15\ 16-51-07\ -\ Some\ Dude-updated.kpabackup
</pre>

The updated backup file is the one that you restore into your KPA.

The `--clean-midi-assignments` option will also verify that the MIDI program number assignments for browse mode are valid.  You should use
this option when you dedupe rigs.

```
Usage: ./kpa.rb [options]
    -f, --file KPABACKUP             kpabackup file.
        --dedupe-rigs
        --clean-midi-assignments
```
