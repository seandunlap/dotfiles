/* Take a stack trace and cross-reference it with a map file. */

parse arg mapfiles

if mapfiles = "" then do
   say "Usage: xref <map-file> [log-file]"
   exit
end

/* ------------------------------------------------------------------------
   Prompt the user to select from the list of map files.
   ------------------------------------------------------------------------ */

filecount = words( mapfiles )
if filecount > 1 & word( mapfiles, 1 ) = "files" then do
   filecount = filecount - 1
   say "Choose map file:"
   do i = 1 to filecount
      say right( i, 3) || ")" word( mapfiles, i+1 )
   end
   response = query( "Enter 1-"filecount": " )
   if datatype( response, "W" ) &,
      response >= 1 &,
      response <= i then do
      mapfile = word( mapfiles, response )
      end
   else do
      if response \= "" then do
         say "Invalid response."
      end
      exit
   end
   end
else do
   parse var mapfiles mapfile logfile
end

if \ exist( mapfile ) then do
   say "Error: Map file not found."
   exit
end

if logfile \= "" &,
   \ exist( logfile ) then do
   say "Error: Log file not found."
   exit
end

/* ------------------------------------------------------------------------
   Read the first line of the map file to find what type it is.
   A "shortmap" file is generated from the ELF file using objdump.
   ------------------------------------------------------------------------ */

maptype = "none"

firstline = linein( mapfile )

select
   when word( firstline, 1 ) == "U" then do
      maptype = "shortmap"
      end
   when word( firstline, 1 ) = "Archive" then do
      maptype = "map"
      end
   otherwise
      testString = strip( translate( substr( firstline, 9, 3 )))
      if testString = "U" |,
         testString = "A" |,
         testString = "W" |,
         testString = "T"   then do
         maptype = "shortmap"
         end
      else do
         say "Error: Can't tell the type of map file."
         exit
      end
end

call close mapfile


/* ------------------------------------------------------------------------
   Prompt the user for a list of entry points.
   Search the map file for all matching function entries.
   ------------------------------------------------------------------------ */

addresscount = 0
subcount = 0
sawblank = 0

grep = "grep"
if exist( "c:/cygwin/bin/grep.exe" ) then do
   grep = "c:/cygwin/bin/grep"
end

tempfile = "temp.xref"
"rm -f" tempfile

if maptype = "shortmap" then do
   grepline = ""
   end
else do
   grepline = "--before=1"
end

newgrepline = grepline

if logfile = "" then do
   say "Map type is" maptype
   say "Enter stack trace, followed by a '.' on a line by itself:"
end
do forever
   traceline = getline()
   /* Rexx can't tell when we hit the end of input, so wait for a ".". */
   if traceline = "." then do
      leave
   end
   parse var traceline word1 thisaddress comments
   comments = strip( comments )
   /* Discard "called from" comments. */
   if left( comments, 11 ) = "called from" then do
      comments = ""
   end
   if word1 = "entry" then do
      if datatype( thisaddress, "x" ) then do
         addresscount = addresscount + 1
         subcount     = subcount + 1
         addresses.addresscount = thisaddress
         comments.addresscount  = strip( comments )

         /* we need to grep and output to our temp file immediately */
         newgrepline = newgrepline || " -e" || thisaddress

         /* grep the map file for our function name and append to tempfile */
         if (subcount = 50) then do
            /*say "Searching 50 addresses.." newgrepline*/
            grep newgrepline mapfile ">>" tempfile
            newgrepline = grepline
            subcount = 0
         end

         end
      else do
         say "Invalid address:" thisaddress
      end
      end
   else do
      addresscount = addresscount + 1
      addresses.addresscount = 0
      comments.addresscount  = traceline
   end
end
if (subcount > 0) then do
   grep newgrepline mapfile ">>" tempfile
   newgrepline = grepline
   subcount = 0
end
if logfile = "" then do
   say "End of input"
end

/*say "Parsed a total of: " addresscount " addresses."*/

if rc \= 0 then do
   say "Error: No matching references found in map file."
   exit
end

/* ------------------------------------------------------------------------
   Parse the results of the search operation above.
   ------------------------------------------------------------------------ */

xref.        = ""
lastfunction = ""

/* With the "--before=1" option, grep will list the ".text.<function-name>"
   lines along with the entries matching addresses.  We can use the section
   name to find the names of static functions - but only in a full map. */
do while lines( tempfile ) > 0
   thisline = linein( tempfile )
   if maptype = "shortmap" then do
      parse var thisline thisaddress thistype thisfunction
      if ( left( thisaddress, 8 ) = "ffffffff" ) then do
         thisaddress = substr( thisaddress, 9 )
      end
      end
   else do
      parse var thisline field1 field2 rest
      /* Ignore separator lines. */
      if field1 = "--" then do
         lastfunction = ""
         iterate
      end
      /* Pull the function name from the section name. */
      if left( field1, 6 ) = ".text." then do
         parse var field1 ".text." lastfunction
         if field2 = "" then do
            iterate
         end
         parse value field2 rest with field1 field2 rest
      end
      /* Ignore lines in the wrong format. */
      if left( field1, 2 ) \= "0x" then do
         iterate
      end
      /* If the second field is a size, it won't have a function name. */
      if left( field2, 2 ) = "0x" then do
         thisfunction = lastfunction
         end
      else do
         thisfunction = field2
         if pos( "(", thisfunction ) \= 0 &,
            pos( ")", thisfunction ) = 0 then do
            parse var rest parameters ")" .
            thisfunction = thisfunction parameters || ")"
         end
      end
      thisaddress = right( field1, 8 )
   end
   if right( thisfunction, 2 ) = ".o" |,
      right( thisfunction, 3 ) = ".o)"  then do
      thisfunction = lastfunction
   end
   thisfunction = strip( thisfunction )
   xref.thisaddress = thisfunction
end

call close tempfile
"rm" tempfile

/* ------------------------------------------------------------------------
   List the matching entry points with the names we found.
   ------------------------------------------------------------------------ */

do i = 1 to addresscount
   thisaddress = addresses.i
   if thisaddress = 0 then do
      say comments.i
      end
   else do
      if xref.thisaddress = "" then do
         say thisaddress comments.i "no match"
         end
      else do
         say thisaddress comments.i xref.thisaddress
      end
   end
end

exit


/* =========================================================================
   Helper functions...
   ========================================================================= */

/* -------------------------------------------------------------------------
   Test whether a file exists
   ------------------------------------------------------------------------- */
exist: procedure
   parse arg File
   /* The query returns an empty string if the file doesn't exist. */
   if stream( file, "C", "QUERY EXISTS" ) = "" then do
      return 0
      end
   else do
      return 1
   end


/* -------------------------------------------------------------------------
   Close a file
   ------------------------------------------------------------------------- */
close: procedure
   File = arg(1)
   call lineout File
return


/* -------------------------------------------------------------------------
   query simply prints a line of text and waits for a response.  It simplifies
   the main program.  If "q" is entered, exit the program.
   Arg 2 may optionally be "no_null", which means a null response is notOK,
   or "no_quit", which means a "q" doesn't force an exit.
   Usage:
      response = query( promptString )
      response = query( promptString, "no_null" )
      response = query( promptString, "no_quit" )
      response = query( promptString, "no_null,no_quit" )
   ------------------------------------------------------------------------- */
query: procedure
   promptString = arg( 1 )
   if arg() > 1 then do
      options = arg( 2 )
      end
   else do
      options = ""
   end

   if pos( ",no_null,", ","options"," ) \= 0 then do
      AcceptNull = 0
      end
   else do
      AcceptNull = 1
   end

   if pos( ",no_quit,", ","options"," ) \= 0 then do
      AcceptQuit = 0
      end
   else do
      AcceptQuit = 1
   end

   /* Keep prompting until the user types something interesting. */
   do until response \= "" | AcceptNull = 1
      /* Print the prompt string and get some input. */
      call charout ,arg(1)
      response = linein()

      /* Quit if user entered "q". */
      if AcceptQuit = 1 & ( response = "q" | response = "Q" ) then do
         exit
      end
   end
return strip( response )


/* -------------------------------------------------------------------------
   Get a line from the log file or from the user.
   ------------------------------------------------------------------------- */
getline:
   if logfile = "" then do
      return linein()
   end
   if lines( logfile ) > 0 then do
      return linein( logfile )
      end
   else do
      return "."
   end
