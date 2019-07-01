/* This script takes a list of modules and sizes (from a linker map file), adds
   the sizes for each file for all sections, and outputs a single line per file.

   The directory listing may be created with the MKS find command:
      find . -name \*.cpp -o -name \*.c -o -name \*.s >dirfile.lis
   Or it may be created with the DOS dir command:
      dir /s/b *.c *.cpp *.s > dirfile.list

   The linker map file should be a normal linker map.  We ignore most of it and
   just look at the list of files included.
   */

parse arg mapfile dirfile outfile rest

bssonly   = 0
addbss    = 0
files     = ""
chip      = "3368"
os        = "ecos"
cablehome = 0

parse arg first rest
do while first \= ""
   select
      when first = "bssonly" then do
         bssonly = 1
      end
      when first = "addbss" then do
         addbss = 1
      end
      when first = "cablehome" then do
         cablehome = 1
      end
      when first = "chip" then do
         parse var rest first rest
         if first = "" then do
            say "Error: Missing chip number."
            exit
         end
         chip = first
      end
      when first = "os" then do
         parse var rest first rest
         if first = "" then do
            say "Error: Missing OS name."
            exit
         end
         os = first
      end
      when first = "help" then do
         call GiveHelp
         exit
      end
      otherwise
         files = files first
   end
   parse var rest first rest
end

if words( files ) > 3 then do
   say "Error: Unexpected parameter" word( files, 4 )
   exit
end

if words( files ) < 2 then do
   say "Error: Expected both map file and dir file names."
   exit
end

parse var files mapfile dirfile outfile

if outfile = "" then do
   outfile = "t.t"
end
"rm" outfile

if lines( mapfile ) = 0 then do
   say "Error: map file not found:" mapfile
   exit
end

if lines( dirfile ) = 0 then do
   say "Error: directory file not found:" dirfile
   exit
end

/* --------------------------------------------------------------- */
/* Basic error checking is done.  Real work starts here. */
/* --------------------------------------------------------------- */

say "Writing output to" outfile

/* Get current working directory, and strip out everything above
   CmDocsisSystem or rbb_cm_src. */
topdir = get_cwd()
parse var topdir topdir "CmDocsisSystem/ecos" .
parse var topdir topdir "rbb_cm_src" .
say "Stop level directory is" topdir

/* Read the directory listing and pull out source file names.  */
curDirectory = ""
fullname.    = ""
do while lines( dirfile ) \= 0

   /* Convert back slashes to forward slashes. */
   line = translate( linein( dirfile ), "/", "\" )

   /* Ignore lines containing "vxworks" or "psos" or "linux". */
   if ( pos( "/VXWORKS", translate( line )) \= 0 & os \= "vxworks" ) |,
      ( pos( "/PSOS", translate( line ))    \= 0 & os \= "psos" ) |,
      ( pos( "/QNX", translate( line ))     \= 0 & os \= "qnx" ) |,
      ( pos( "/LINUX", translate( line ))   \= 0 & os \= "linux" ) then do
      iterate
   end

   /* I can't remember how I generated a listing of files in this format, but
      it won't hurt to leave it in. */
   if pos( ":", line ) \= 0 & pos( ":", line ) \= 2 then do
      parse var line curDirectory ":"
      end
   else do
      /* If this is a normal "find . -name \*.c -print" listing, handle it. */
      if pos( "/", line ) \= 0 then do
         lastSlashPos = lastpos( "/", line )
         curDirectory = substr( line, 1, lastSlashPos - 1 )
         name         = substr( line, lastSlashPos + 1 )
      end
      uname = translate( name )
      if right( uname, 2 ) == ".C" | right( uname, 2 ) == ".S" | right( uname, 4 ) == ".CPP" then do
         if right( uname, 2 ) == ".C" | right( uname, 2 ) == ".S" then do
            objname = left( name, length( name ) - 2 ) || ".o"
            end
         else do
            objname = left( name, length( name ) - 4 ) || ".o"
         end
         /* For chip-specific files, use the one from the specified chip BSP. */
         if pos( "bsp_bcm9", line ) \= 0 &,
            pos( chip, line ) == 0 then do
            iterate
         end
         /* Don't let bsp_common files supersede chip-specific files. */
         if pos( "bsp_common", line ) \= 0 &,
            pos( chip, fullname.objname ) \= 0 then do
            iterate
         end
         /* Ignore the old CmHal_* directories. */
         if pos( "CmHal_", line ) \= 0 then do
            iterate
         end
         /* Skip CableHome firewall files when not built with CH. */
         if cablehome = 0 &,
            pos( "CableHome", line ) \= 0 then do
            iterate
         end
         /* Ignore CmVendor directories. */
         if pos( "/CmVendor/", line ) \= 0 then do
            iterate
         end
         fullname.objname = line
      end
   end

end


/* Skip to the line which matching "END GROUP".  This is the start of the list
    of sections and sizes. */
do while lines( mapfile ) \= 0
   line = linein( mapfile )
/*   if line = "END GROUP" then do */
   if line = "Linker script and memory map" then do
      leave
   end
end


/* Start with a section name which won't match anything in a real map file.
   This also won't match a null section name in a blank line. */
section = "ignore"

/* These are the only sections we're interested in, since they contribute to
   the size of the binary (.bin).  Other sections contribute only to the RAM
   usage - .bss, .sbss, etc. */
if bssonly then do
   sections = ".bss .sbss "
   end
else do
   sections = ".text .data .rodata .sdata .ctors .dtors .devtab .romtext .ramtext "
   if addbss then do
      sections = sections || ".bss .sbss "
   end
end

fill = 0

/* Read list of sections and pull out sizes for each file. */
do while lines( mapfile ) \= 0

   line = linein( mapfile )

   /* Look for only sections in the following list. */
   if left( line, 1 ) = "." then do
      section = word( line, 1 )
      if pos( section||" ", sections ) = 0 then do
/*         say "   Ignoring" section */
         section = "ignore"
         end
      else do
         say "Parsing section" section
      end
      if section = ".romtext" | section = ".ramtext" then do
         section = ".text"
      end
      iterate
   end

   if section = "ignore" then do
      iterate
   end

   linesection = word( line, 1 )
   /* The new compiler generates function sections, so we have to look at only
      the leading part of the section name, between the dots. */
   parse var linesection junk "." sectionName "."
   if junk \= "" then do
      if junk = "COMMON" |,
         junk = "*fill*" ,
         then do
         lineSection = junk
         end
      else do
         iterate
      end
      end
   else do
      linesection = "." || sectionName
   end

   /* The "*fill*" lines are oddly formatted.  The fill size is prepended with
      some strange hex number.  The fill value is in the last 8 digits. */
   if linesection = "*fill*" then do
      fillsize = x2d( right( word( line, 3 ), 8 ))
      fill = fill + fillsize
      iterate
   end

   /* Ignore all lines which don't match the current section.  These will be
      detail lines for symbols within the module, or info on sections we're
      not interested in.  The linker may put the .rodata section in with the
      .text section, so handle that as a special case. */
   if linesection \= section &,
      linesection \= ".rodata" &,
      linesection \= ".gnu" &,
      linesection \= ".ecos" &,
      linesection \= ".scommon" &,
      linesection \= "COMMON" ,
            then do
      iterate
   end

   /* Handle an oddly-named section with "*" in the name, and several spaces. */
   if words( line ) > 4 &,
      pos( '*', word( line, 1 )) \= 0 then do
      line = word( line, 1 )
   end

   /* If the section name is very long, it will be on a line by itself.  We
      need to get the next line and append it. */
   if words( line ) = 1 then do
      line = line linein( mapfile )
   end

   /* The file name is the last word, but it may have "(overhead...)" appended.
      Strip off the "(overhead...) string. */
   parse var line line "(overhead" .
   filename = translate( word( line, words( line ) ), "/", "\" )

   /* Word 3 is the size in hex.  It may be prefixed with "0x", so remove prefix. */
   hexsize  = translate( word( line, 3 ))
   if left( hexsize, 2 ) = "0X" then do
      hexsize = substr( hexsize, 3 )
   end
   /* Convert size to decimal. */
   if \ datatype( hexsize, "X" ) |,
      hexsize = '' then do
      say line
      iterate
   end
   size = x2d( hexsize )

   /* Look up file name in list.  If not found, use as is in the map file. */
/*   ufilename = translate( filename ) */
   if fullname.filename \= "" then do
      filename = fullname.filename
      end
   /* Name not in list.  Try to remove the directory prefix. */
   else do
      filename = DeletePrefix( filename, topdir )
   end
   call lineout outfile, left( filename, max( 70, length( filename ))) left( section, 8 ) "-" right( size, 7 )

end

say "Fill =" fill

call lineout outfile, ""

exit


GiveHelp:
   say "This script takes a list of modules and sizes (from a linker map file), finds"
   say "the size for each file, and outputs a single line per file per section.  The"
   say "file names are translated back to the original source file names."
   say ""
   say "The linker map file should be a fulllinker map.  We ignore most of it and just"
   say "look at the list of sections and sizes.  Normally only the .text, .data, and"
   say ".rodata sections are included in the totals."
   say ""
   say "The directory listing may be created with the DOS dir command:"
   say "   dir /s/b *.c *.cpp *.s > dirfile.list"
   say "Or the Unix find command:"
   say "   find . -name \*.cpp -o -name \*.c -o -name \*.s >dirfile.lis"
   say ""
   say "Usage: parsemap <map-file> <directory-list> [output-file] [option...]"
   say ""
   say "Options:"
   say "   addbss    - Also list info about .bss and .sbss sections"
   say "   bssonly   - Only list info about bss sections"
   say "   chip <chipnum> - Use the specified chip's BSP instead of the 3368"
exit





/* -------------------------------------------------------------------------
   Get the current working directory.
   Usage:
      cwd = get_cwd()
   ------------------------------------------------------------------------- */
get_cwd: procedure

   junk = popen( 'pwd', 'cwd.' )

return cwd.1


/* --------------------------------------------------------------------------
   Compare the first part of theString with prefix.  If they match, delete
   prefix from the beginning of theString.  An optional argument causes case
   to be ignored.
   Usate:
      newString = DeletePrefix( oldString, prefix )
      newString = DeletePrefix( oldString, prefix, "ignore_case" )
   -------------------------------------------------------------------------- */
DeletePrefix: procedure
   theString = arg( 1 )
   prefix    = arg( 2 )
   option    = arg( 3 )
   matchLen  = length( prefix )
   if option = "ignore_case" then do
      compareString = translate( theString )
      comparePrefix = translate( prefix )
      end
   else do
      compareString = theString
      comparePrefix = prefix
   end
   if left( compareString, matchLen ) = comparePrefix then do
      theString = substr( theString, matchLen + 1 )
   end
return theString
