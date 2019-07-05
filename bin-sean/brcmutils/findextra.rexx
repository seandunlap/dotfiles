/*
   Search the current directory tree for files which do not belong to any
   project.
*/

keep           = 0
delete         = 0
lower          = 1
buildfiles     = 0
objects        = 1
defaultyes     = 1
recurse        = 1
batch          = 0

ValidParameters = "keep delete buildfiles objects defno recurse batch"

parse arg parm rest
do while parm \= ""
   if parm = "help" | parm = "-help" | parm = "--help" | parm = "-?" then do
      call GiveHelp
      exit
   end
   ParmOk = 0
   /* Loop through the valid parameter and set the appropriate variable if we
      find a match. */
   do i = 1 to words( ValidParameters )
      TestParm = word( ValidParameters, i )
      if parm = TestParm then do
         ParmOk = 1
         interpret TestParm "= 1"
         leave
      end
      if parm = "no"TestParm then do
         ParmOk = 1
         interpret TestParm "= 0"
         leave
      end
   end
   if ParmOk = 0 then do
      say "Unrecognized parameter" parm
      exit
   end
   parse var rest parm rest
end


shell = "DOS"
rm    = "del /f"
slash = "\"

junk = popen( "which sort", "which." )
if pos( "/bin/sort", which.1 ) \= 0 then do
   lower  = 0
   shell  = "Bash"
   rm     = "rm -f"
   slash  = "/"
end

if recurse then do
   /* get a sorted list of all files in all subdirectories, excluding directories */
   /* get a list of project files in all subdirectories */
   if shell = "Bash" then do
      cwd = directory()
      "find . -type f      | sed -e 's,^\./,"cwd"/,' | sort >dir.sort"
      "find . -name \*.use | sed -e 's,^\./,"cwd"/,' >pj.lis"
      end
   else do
      "dir /s /b /a:-d | sort >dir.sort"
      "dir /s /b *.use >pj.lis"
   end

   end
else do
   if shell = "Bash" then do
      cwd = directory()
      "find . -type f      -maxdepth 1 | sed -e 's,^\./,"cwd"/,' | sort >dir.sort"
      "find . -name \*.use -maxdepth 1 | sed -e 's,^\./,"cwd"/,' >pj.lis"
      end
   else do
      cwd = translate( directory(), "/", "\" )

      /* get a sorted list of all files, excluding directories */
      /* add the current directory to each file name */
      'dir /b /a:-d | sed -e "s,^,'||cwd||'/," -e "s,/,\\,g" | sort >dir.sort'

      /* get a list of project files */
      /* add the current directory to each file name */
      'dir /b *.use | sed -e "s,^,'||cwd||'/," -e "s,/,\\,g" >pj.lis'
   end
end

pjlist = "pj.lis"
pjcatlist = "pjcat.lis"

if shell = "Bash" then do
   "rm -f pjcat.lis"
   end
else do
   "if exist pjcat.lis del /f pjcat.lis"
end

/*
for each project file
   find the directory
   for each line in the .use file
      substitute the directory for $(projectdir)
*/
do while lines( pjlist ) \= 0
   pjfile = linein( pjlist )
   pjdir  = substr( pjfile, 1, lastpos( slash, pjfile ) - 1 )
   do while lines( pjfile ) \= 0
      thisline = RemoveChar( linein( pjfile ), '"' )
      parse value reverse( thisline ) with version x y z rfullpath
      archived = 1
      if version = "f" | pos( ".", version ) = 0 then do
         archived = 0
         parse value reverse( thisline ) with . . . rfullpath
      end
      fullpath = strip( reverse( rfullpath ))
      newline = pjdir || substr( fullpath, pos( ")", fullpath ) + 1 )
      newline = translate( newline, slash, "/" )
      newline = changestr( "//", newline, "/" )
      newline = changestr( "\\", newline, "\" )
      call lineout pjcatlist, newline
/*      if archived = 0 then do
         say "File not archived:" substr( fullpath, pos( ")", fullpath ) + 1 )
      end */
   end
end

/* Sort concatenated list of project member files.  Remove any double-slashes. */
if shell = "Bash" then do
   "sort <pjcat.lis >pjcat.sort"
   end
else do
   'sort <pjcat.lis >pjcat.sort'
end

uselist = "pjcat.sort"
dirlist = "dir.sort"

oldusefile = ""
usefile = linein( uselist )
dirfile = linein( dirlist )

/* Go through the two file lists to see where they don't match.  This could be
   due to files which are not part of a project, or files missing from a project,
   or files which are in more than one project.  */
do while ( usefile \= "~" ) | ( dirfile \= "~" )
   /* Ignore Source Integrity project files and the directory listing. */
   if rightmatch( dirfile, ".use" ) |,
      rightmatch( dirfile, ".pj" ) |,
      rightmatch( dirfile, "dir.sort" ) then do
      dirfile    = readline( dirlist )
      iterate
   end
   /* Ignore subprojects. */
   if ( rightmatch( usefile, ".use" ) | rightmatch( usefile, ".pj" )) then do
      oldusefile = usefile
      usefile    = readline( uselist )
      iterate
   end

   /* Now compare the file names.  The names are translated to lowercase before
      comparison because this appears to be the algorithm used by the DOS "sort"
      utility. */
   select
      when lower( usefile ) = lower( dirfile ) then do
         if usefile \= dirfile then do
            say "Case doesn't match:" dirfile
            if delete then do
               if defaultyes = 1 then do
                  response = query( "Delete? (y/n)[y] " )
                  if response = "" | response = "y" then do
                     address system rm '"' || dirfile || '"'
                  end
                  end
               else do
                  response = query( "Delete? (y/n)[n] " )
                  if response = "y" then do
                     address system rm '"' || dirfile || '"'
                  end
               end
            end
         end
         dirfile    = readline( dirlist )
         oldusefile = usefile
         usefile    = readline( uselist )
         if ( oldusefile = usefile ) & ( usefile \= "Z" ) then do
            say "File in more than one project:" usefile
            usefile    = readline( uselist )
         end
         end
      when lower( usefile ) < lower( dirfile ) then do
         say "Missing file:" usefile
         oldusefile = usefile
         usefile    = readline( uselist )
         if oldusefile = usefile then do
            say "File in more than one project:" usefile
         end
         end
      when lower( usefile ) > lower( dirfile ) then do
         parse value reverse( dirfile ) with . (slash) rlastdir1 (slash) rlastdir2 (slash) rlastdir3 (slash) .
         lastdir1 = reverse( rlastdir1 )
         lastdir2 = translate( reverse( rlastdir2 ))
         lastdir3 = reverse( rlastdir3 )
         if buildfiles  = 0 &,
            (( lastdir1 = "objs" ) |,
             (left( lastdir1, 4 ) = "bcm9" &,
              (( lastdir2 = "VXWORKS" ) |,
               ( lastdir2 = "ECOS" )    |,
               ( lastdir2 = "QNX" )    |,
               ( lastdir2 = "PSOS" )))) then do
            nop
            end
         else if objects = 0 & ,
                 rightmatch( dirfile, ".o" ) then do
            nop
            end
         else if rightmatch( dirfile, ".o" ) &,
            (( lastdir1 = "objs" ) |,
             ( lastdir2 = "VXWORKS" ) |,
             ( lastdir2 = "ECOS" )    |,
             ( lastdir2 = "QNX" )    |,
             ( lastdir2 = "PSOS" )) then do
            nop
            end
         else do
            call ExtraFile dirfile
            if delete then do
               if defaultyes = 1 then do
                  response = query( "Delete? (y/n)[y] " )
                  if response = "" | response = "y" then do
                     address system rm '"' || dirfile || '"'
                  end
                  end
               else do
                  response = query( "Delete? (y/n)[n] " )
                  if response = "y" then do
                     address system rm '"' || dirfile || '"'
                  end
               end
            end
         end
         dirfile = readline( dirlist )
         end
   end
end

call close "dir.sort"
call close "pjcat.sort"
call close "pj.lis"
call close "pjcat.lis"

if keep = 0 then do
   address system rm "dir.sort"
   address system rm "pjcat.sort"
   address system rm "pj.lis"
   address system rm "pjcat.lis"
end

exit


/* ========================================================================= */
/* ========================================================================= */

/*
   ReadLine takes the place of linein.  If we've reached the end of the file,
   it returns a value ("Z") which should be greater than any value in a "normal"
   input line.  This simplifies the logic of the above "do" loop.
*/
ReadLine:
   parse arg filename
   if lines( filename ) \= 0 then do
      return linein( filename )
      end
   else do
      return "~"
   end


/* -------------------------------------------------------------------------
   Translate a string to lowercase, and change any backslash characters to spaces.
*/
lower:
   parse arg inString
   if lower = 0 then do
      return inString
      end
   else do
      return translate( instring, "abcdefghijklmnopqrstuvwxyz/", "ABCDEFGHIJKLMNOPQRSTUVWXYZ\" )
   end


/* -------------------------------------------------------------------------
*/
RemoveChar:
   haystack = arg( 1 )
   needle   = arg( 2 )
   n_pos    = pos( needle, haystack )
   do while n_pos \= 0
      haystack = left(   haystack, n_pos - 1 ) ||,
                 substr( haystack, n_pos + 1 )
      n_pos = pos( needle, haystack )
   end
return haystack


/* -------------------------------------------------------------------------
*/
close:
   Thisfile = arg(1)
   call stream ThisFile, "C", "CLOSE"
return


/* -------------------------------------------------------------------------
   query simply prints a line of text and waits for a response.  It simplifies
   the main program.
   ------------------------------------------------------------------------- */
query: procedure
   call charout ,arg(1)
return linein()
/* end of query */


/* -------------------------------------------------------------------------
   rightmatch tests whether the rightmost part of a string matches a second
   string.
   ------------------------------------------------------------------------- */
rightmatch: procedure
   string1 = arg(1)
   string2 = arg(2)
   if right( string1, length( string2 )) == string2 then
      return 1
   else
      return 0
/* end of rightmatch */


ExtraFile: procedure expose batch rm slash
   parse arg dirfile
   if batch then do
      say rm translate( dirfile, slash, "/" )
      end
   else do
      say "File not in project:" dirfile
   end
return

/* -------------------------------------------------------------------------
   GiveHelp.
   ------------------------------------------------------------------------- */
GiveHelp: procedure
   say "Findextra looks for sandboxes or projects in the current directory and"
   say "lists which files are missing or don't belong to any project.  Object"
   say "files in build directories are not normally shown."
   say
   say "Usage: findextra [options...]"
   say
   say "Options:"
   say "    delete       - prompt to delete files which don't belong to any project"
   say "    defno        - default to ""no"" at delete prompt"
   say "    batch        - create a script which you can run to delete the files"
   say "    buildfiles   - also list files in the usual BFC/V2 build directories"
   say "    noobjects    - don't list object files"
   say "    norecurse    - don't look in subdirectories"
   say "    keep         - keep intermediate files"
return
/* end of GiveHelp */
