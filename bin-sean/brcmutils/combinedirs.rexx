/* Parse a sorted list of file names and section sizes.  Sum the sizes for all
   sections for each file name. */

parse arg infile outfile

if infile = "" then do
   say "Usage: combine <infile> [outfile]"
   exit
end

currentname = "bogus"
currentsize = 0
dirsizes.   = 0
dirnames.   = ""
dircount    = 0

if outfile = "" then do
   outfile = "t.combinedirs"
end
say "Writing to" outfile

"rm -f" outfile

do while lines( infile ) \= 0
   thisline = linein( infile )
   if thisline = "" then do
      iterate
   end
   thisname = word( thisline, 2 )
   thissize = word( thisline, 1 )

   /* Treat each library as a directory. */
   if pos( ".a(", thisname ) \= 0 then do
      parse var thisname thisdir "(" .
   end
   else do
      parse value reverse(thisname) with . "/" revdir
      thisdir = reverse( revdir )
   end

   if dirsizes.thisdir = 0 then do
      dircount = dircount + 1
      dirnames.dircount = thisdir
   end

   dirsizes.thisdir = dirsizes.thisdir + thissize
end

say dircount "total directories"

do i = 1 to dircount
   thisname = dirnames.i
   call lineout outfile, right( dirsizes.thisname, 7) thisname
end
