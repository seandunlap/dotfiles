/* Add up the numbers in the nth column of a text input file. */

parse arg filename n base .

if datatype( n, "w" ) \= 1 then do
   say "Usage: sumcol <filename> <column-number>"
   exit
end

if lines( filename ) = 0 then do
   say "File empty or not found:" filename
   exit
end

sum = 0
lineNumber = 0

do while lines( filename ) \= 0
   theLine    = linein( filename )
   lineNumber = lineNumber + 1
   /* Skip blank lines */
   if theLine = "" then do
      iterate
   end
   aNum    = word( theLine, n )
   if base = 16 then do
      if left( aNum, 2 ) = "0x" then do
         aNum = substr( anum, 3 )
      end
      aNum = x2d( aNum )
   end
   if datatype( aNum, "w" ) \= 1 then do
      say "Warning: Non-number found on line" lineNumber".  Treating as zero."
      aNum = 0
   end
   sum = sum + aNum
end

say "Total of column" n":" sum
