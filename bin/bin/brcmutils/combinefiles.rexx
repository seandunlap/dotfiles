/* Parse a list of file contributions to image size, and give each file's
   section contributions. */

parse arg infile

if infile = "" then do
   say "Usage: combinefiles <in-file>"
   exit
end

filename = "bogus"
section  = ""
size     = 0
do while lines( infile ) \= 0
   thisline = linein( infile )
   parse var thisline thisname thissect . thissize
   /* If this file name and section name match the previous one, accumulate size. */
   if thisname = filename &,
      thissect = section   then do
      size = size + thissize
      iterate
   end
   /* File name or section name didn't match.  Print info if valid. */
   if filename \= "bogus" then do
      say left( filename, max( 70, length( filename ))) left( section, 8 ) "-" right( size, 7 )
   end
   filename = thisname
   section  = thissect
   size     = thissize
end
say left( filename, max( 70, length( filename ))) left( section, 8 ) "-" right( size, 7 )
