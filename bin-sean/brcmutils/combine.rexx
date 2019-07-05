/* Parse a sorted list of file names and section sizes.  Sum the sizes for all
   sections for each file name. */

parse arg infile namecolumn sizecolumn outfile

if sizecolumn = "" then do
   say "Usage: combine <infile> <namecolumn> <sizecolumn>"
   exit
end

currentname = "bogus"
currentsize = 0

if outfile = "" then do
   outfile = "t.combine"
end
say "Writing to" outfile

"rm -f" outfile

do while lines( infile ) \= 0
   thisline = linein( infile )
   thisname = word( thisline, namecolumn )
   thissize = word( thisline, sizecolumn )

   if thisname \= currentname then do
      if currentname \= "bogus" then do
         call lineout outfile, right( currentsize, 7 ) currentname
      end
      currentname = thisname
      currentsize = thissize
      iterate
   end
   currentsize = currentsize + thissize
end

if currentname \= "bogus" then do
   call lineout outfile, right( currentsize, 7 ) currentname
end

call close infile
call close outfile

exit

/* -------------------------------------------------------------------------
   Close a file.
   Usage:
      call close( theFile )
   ------------------------------------------------------------------------- */
close: procedure
   Thisfile = arg(1)
   call stream ThisFile, "C", "CLOSE"
return
