#!/bin/bash

function show_help()
{
        echo "Usage: get_bcm3390b0smwvg_monolith.sh"
        echo -e $ "This utility creates a 3390 B0 monolith image using the nightly images from /projects/rbbswbld-store/images/nightly\n"
        echo "Default values: [DATE:$target_date]  [BRANCH:$branch]  [TARGET:$target]"
        echo -e $"\nOptional args:"
        echo -e $"\n-b: specify branch [ accepted values: develop, Prod_6.1.0, Prod_6.1.1. default is develop. ]\n"
        echo -e $"-d: specify build date [ use format yyyy-mm-dd. example: 2016-05-20. ]\n"
        echo -e $"-f: specify docsis image name [ !!WARNING!!: Specified docsis image must be the correct match for the target $target.\n"
        echo -e $"                             Default behavior: script will search for the following bcm3390<target>_fat.bin, bcm3390<target>_comcast_fat.bin, bcm3390<target>_comcast_virtnihal_fat.bin ]\n"
        echo "-x: specify CXC version [ accepted values: PC15, PC20. default is PC15. ]"
        echo "-h or ? [show this help]"
}

function clean_up()
{
    # Cleanup of images created by ProgramStore header, temp params file, etc
    for file_to_delete in "${files_to_delete[@]}"
    do
	    #echo "DEBUG: File to delete: $file_to_delete"
	    rm -rf $file_to_delete
    done
}

function cmubifs()
{
       # This script will find the latest bootloader directory
       # path="/projects/rbbswbld-store/images/nightly/CmBootloader270/*"
        # latest_bootloader=$(find $path -type d -prune | tail -n 1)
       mkdir  -p temp_ubifs
       if [ -d "temp_ubifs" ]
       then
	chmod 777 -R  temp_ubifs/
	cp /projects/rbbswbld-store/images/nightly/CmBootloader270/2016-04-17/bootloader93390mwvg__slim_jtag.bin temp_ubifs/cmboot.bin
	mv cmrun1.bin temp_ubifs/cmrun1.bin
	build_cm_images.sh -d temp_ubifs -t 3390b0
	rm -rf temp_ubifs
      fi
}

target_date=
DAYOFWEEK=$(date +"%u")

if [ "$DAYOFWEEK" == 1 ]
then
   target_date=$(date +%Y-%m-%d -d "3 day ago")
else
   target_date=$(date +%Y-%m-%d -d yesterday)
fi

chip=3390b0
branch=develop
output_directory="."
target=smwvg
cm_filename=
cxc_version=PC15

#we need a directory and a target from the user
while getopts "h?d:b:f:x:" opt; do
        case "$opt" in
        h|\?)
                show_help
                exit 0
                ;;
        d)  target_date=$OPTARG
                ;;
        b)  branch=$OPTARG
                ;;
        f)  cm_filename=$OPTARG
               ;;
        x)  cxc_version=$OPTARG
               ;;
        esac
done

if [ $# -eq 0 ]
then
	echo "Using DATE:$target_date BRANCH:$branch TARGET:$target"
        #show_help
        #exit 1
fi

case "$cxc_version" in
"PC15"| "PC20")
	;;
*)
	echo "Unrecognized CXC version: $cxc_version, exiting..."
	exit 1
	;;
esac

if [ "$cm_filename" != "" ]
then
    get_monolith.sh -t smwvg -d $target_date -b $branch -x $cxc_version -f $cm_filename
else
    get_monolith.sh -t smwvg -d $target_date -b $branch -x $cxc_version
 fi
