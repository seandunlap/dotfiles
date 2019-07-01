#!/bin/bash
##############################################################################
#
#  Copyright (c) 2003-2016 Broadcom Corporation
#
#  This program is the proprietary software of Broadcom Corporation and/or
#  its licensors, and may only be used, duplicated, modified or distributed
#  pursuant to the terms and conditions of a separate, written license
#  agreement executed between you and Broadcom (an "Authorized License").
#  Except as set forth in an Authorized License, Broadcom grants no license
#  (express or implied), right to use, or waiver of any kind with respect to
#  the Software, and Broadcom expressly reserves all rights in and to the
#  Software and all intellectual property rights therein.  IF YOU HAVE NO
#  AUTHORIZED LICENSE, THEN YOU HAVE NO RIGHT TO USE THIS SOFTWARE IN ANY WAY,
#  AND SHOULD IMMEDIATELY NOTIFY BROADCOM AND DISCONTINUE ALL USE OF THE
#  SOFTWARE.
#
#  Except as expressly set forth in the Authorized License,
#
#  1.     This program, including its structure, sequence and organization,
#  constitutes the valuable trade secrets of Broadcom, and you shall use all
#  reasonable efforts to protect the confidentiality thereof, and to use this
#  information only in connection with your use of Broadcom integrated circuit
#  products.
#
#  2.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE SOFTWARE IS PROVIDED
#  "AS IS" AND WITH ALL FAULTS AND BROADCOM MAKES NO PROMISES, REPRESENTATIONS
#  OR WARRANTIES, EITHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, WITH
#  RESPECT TO THE SOFTWARE.  BROADCOM SPECIFICALLY DISCLAIMS ANY AND ALL
#  IMPLIED WARRANTIES OF TITLE, MERCHANTABILITY, NONINFRINGEMENT, FITNESS FOR
#  A PARTICULAR PURPOSE, LACK OF VIRUSES, ACCURACY OR COMPLETENESS, QUIET
#  ENJOYMENT, QUIET POSSESSION OR CORRESPONDENCE TO DESCRIPTION. YOU ASSUME
#  THE ENTIRE RISK ARISING OUT OF USE OR PERFORMANCE OF THE SOFTWARE.
#
#  3.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL BROADCOM
#  OR ITS LICENSORS BE LIABLE FOR (i) CONSEQUENTIAL, INCIDENTAL, SPECIAL,
#  INDIRECT, OR EXEMPLARY DAMAGES WHATSOEVER ARISING OUT OF OR IN ANY WAY
#  RELATING TO YOUR USE OF OR INABILITY TO USE THE SOFTWARE EVEN IF BROADCOM
#  HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES; OR (ii) ANY AMOUNT IN
#  EXCESS OF THE AMOUNT ACTUALLY PAID FOR THE SOFTWARE ITSELF OR U.S. $1,
#  WHICHEVER IS GREATER. THESE LIMITATIONS SHALL APPLY NOTWITHSTANDING ANY
#  FAILURE OF ESSENTIAL PURPOSE OF ANY LIMITED REMEDY.
#
##############################################################################

function show_help()
{
	echo "VERSION 1.0"
	echo "parameter file needed to proceed"
	echo "Usage: create_monolith_rglinux.sh"
	echo "Required args:"
	echo "-f <paramfile> [this is the partition/file mapping that would normally be given to mkmonolith]"
	echo "Optional args"
	echo "-z [apply gzip to all images, default is not to gzip]"
	echo "-b [supply name for output monolith, default is monolith.bin]"
	echo "-p [supply pid value, default is 3390]"
	echo "-c [supply chip id and revision, accepted values: 3390A, 3390B. default is 3390A. ]"
	echo "-h or ? [show this help]"
}

if [ $# -eq 0 ]
then
	show_help
	exit 1
fi

compress=0
monolith="monolith.bin"
paramfile=
pid=3390
chiprev=3390A

while getopts "h?zf:b:p:c:" opt; do
	case "$opt" in
	h|\?)
		show_help
		exit 0
		;;
	z)  compress=1
		;;
	f)  paramfile=$OPTARG
		;;
	b)  monolith=$OPTARG
		;;
	p)  pid=$OPTARG
		;;
	c)  chiprev=$OPTARG
		;;
	esac
done

if [ ! -f $paramfile ]
then
	echo "parameter file supplied with -f argument ($paramfile) not found, exiting..."
	exit 1
fi

if [ ! -p `echo $pid | tr -d "[:xdigit:]"` ]; then
   echo "Error: input contains non-hex characters"
	exit 1
fi
if [ -c ]; then
    if [ $chiprev != "3390B" ]; then
     if [ $chiprev != "3390A" ]; then
	echo "Error: if specified then version must be 3390A or 3390B! Default version is 3390A."
	    exit 1
    fi
    fi
fi

# Declare arrays to track which images and partitions are being used.
declare -A params=(); #Associative array
declare -a files_to_delete=(); # Array with integers for keys
while read line; do

	# Split line into partition and filename from the : character.
	# Try to also enforce simple rules for names.
	# Note, the dash character will cause a range match unless it is the first character...
	if [[ $line =~ ^[[:space:]]*([[:alpha:]]+)[[:space:]]*:[[:space:]]*([-[:alnum:]_.]+) ]]; then
		partition=${BASH_REMATCH[1]}
		filename=${BASH_REMATCH[2]}
		params[$partition]=$filename
	else
		partition="Unknown"
		filename="Unknown"
	fi

	if [ $partition = "Unknown" ] || [ $filename = "Unknown" ]; then
		echo "Skipping =$line=, either the partition or filename does not follow expected input rules."
		continue
	fi

	# The DOCSIS partition is assumed to already have a ProgramStore header, as this is the default.
	if [ $partition != "DOCSIS" ]
	then
		if [ ! -s $filename ]; then
		echo "ERROR: Failed to find $filename!"
		exit 1
		fi
		# Get the size of the image as ProgramStore header uses this for validation after download
		filesize=`cat $filename | wc -c`

		# If requested, compress the image with qzip
		if [ $compress -eq 1 ]
		then
			gzip $filename
			mv $filename.gz $filename
		fi

		# Add the pid to the filename of the image output from ProgramStore header.
		temp_filename=$filename.$pid
		ProgramStore -f $filename -o $temp_filename -s $pid -c 0 -u $filesize -d

		# The file with the ProgramStore header needs to be passed to mkmonolith
		params[$partition]=$temp_filename

		# Decompress the input image so it is the same as when the script started
		if [ $compress -eq 1 ]
		then
			mv $filename $filename.gz
			gunzip $filename.gz
		fi

		# Store the list of images created in this script so that they can be cleaned up.
		files_to_delete=("${files_to_delete[@]}" $temp_filename)
	fi
done < $paramfile

#echo "DEBUG: Array keys: ${!params[@]}" ;# Keys
#echo "DEBUG: Array values ${params[@]}" ;# Values

# Now that we have a list of all of the partitions, check if the combination is allowed.
CM=0
DOCSIS=0
BOOTL=0
for part in "${!params[@]}"
do
	if [ $part = "CM" ]; then CM=1; fi
	if [ $part = "DOCSIS" ]; then DOCSIS=1; fi
	if [ $part = "BOOTL" ]; then BOOTL=1; fi
	#	echo "DEBUG: Partitions in use: $part"
done

# Create the param.txt file to pass into the mkmonolith utility
monolith_params_file=param.txt.$pid
echo "# Temp file for mkmonolith" > $monolith_params_file
files_to_delete=("${files_to_delete[@]}" $monolith_params_file)

if [ $CM -eq 1 -a $DOCSIS -eq 1 ]; then echo "WARNING: Input params contain both the CM and the DOCSIS partition, this may lead to complications."; fi
if [ $CM -eq 1 -a $BOOTL  -eq 1 ]; then echo "WARNING: Input params contain both the CM and the BOOTL partition, this may lead to complications."; fi
for part in "${!params[@]}"
do
	if [ $part = "DOCSIS" -a $CM -eq 1 -a $DOCSIS -eq 1 ]; then echo "Skipping DOCSIS as CM was included"; continue; fi
	if [ $part = "BOOTL"  -a $CM -eq 1 -a $BOOTL  -eq 1 ]; then echo "Skipping BOOTL as CM was included"; continue; fi
	echo $part " : " ${params[$part]} >> $monolith_params_file
done

# Call the external monolithic image creation utility.
mkmonolith_rglinux -c $chiprev -p param.txt.$pid -o $monolith

# The monolith output does not have the permissions needed for download.
chmod 777 $monolith

# DEBUG, uncomment to see which files are in the monolith params file
# cat $monolith_params_file ;#DEBUGJAH

# Cleanup of images created by ProgramStore header, temp params file, etc
for file_to_delete in "${files_to_delete[@]}"
do
	#echo "DEBUG: File to delete: $file_to_delete"
	rm -rf $file_to_delete
done
