#!/bin/bash

function show_help()
{
        echo "Usage: get_monolith.sh"
        echo -e $ "This utility creates a 3390 B0 monolith image using the nightly images from /projects/rbbswbld-store/images/nightly\n"
        echo "If no options are specified DATE:latest BRANCH:develop TARGET:smwvg"
        echo "Optional args:"
        echo "-b <branch> [ this is the branch directory. accepted values: Prod_6.1.0, Prod_6.1.1, Prod_6.1.2, develop. default is develop. ]"
        echo "	      important: DOCSIS image  is selected from the respective PC15 directory. ]"
        echo "-d <target_date> [ this is the target date of the nightly images. use format yyyy-mm-dd. example: 2016-05-20. ]"
        echo "-f <cm_filename> [ this is the DOCSIS image (not ubifs). default value is created based on the target and branch. "
        echo "	           this value overrides -t <target> value.]"
        #echo "-c <chip> [ supply chip id and revision, default is 3390b0. ]"
        echo "-t <target> [ this is the target. accepted values: smwvg, wvg, dcm. default is smwvg. ]"
        echo "              this value is ignored if -f <cm_filename> is specified. ]"
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
	cp temp_ubifs/cmrun1.bin temp_ubifs/cmrun0.bin
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
while getopts "h?d:b:c:t:f:x:" opt; do
        case "$opt" in
        h|\?)
                show_help
                exit 0
                ;;
        c)  chip=$OPTARG
                ;;
        d)  target_date=$OPTARG
                ;;
        b)  branch=$OPTARG
                ;;
        t)  target=$OPTARG
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

case "$branch" in
"Prod_6.1.0"| "Prod_6.1.1"| "Prod_6.1.2"| "develop")
	;;
*)
	echo "Unrecognized target directory: $branch dir, exiting..."
	exit 1
	;;
esac

case "$target" in
"smwvg"| "mwvg"| "dcm")
	;;
*)
	echo "Unrecognized target: $target, exiting..."
	exit 1
	;;
esac

case "$chip" in
"3390b0")
	monolith_target=3390B
	;;
*)
	echo "Unrecognized target: $target, exiting..."
	exit 1
	;;
esac

#case $chip in
#	"3390a0"| "3390a0-dcm")
#		monolith_target=3390A
#		;;
#
#	"3390b0")
#		monolith_target=3390B
#		;;
#
#	*) echo "Invalid target: $target"
#		exit 1
#		;;
#esac

# Declare arrays to track which images and partitions are being used.
declare -A params=(); #Associative array
declare -a files_to_delete=(); # Array with integers for keys

# Nightly folder.
nightly_folder=/projects/rbbswbld-store/images/nightly/

	# check if the folder exists
	[ -d $nightly_folder/$branch-RGLinux/$target_date ]
	if [ $? -ne 0 ]
	then
		echo -e $"\n!!!ERROR!!! $target_date directory does not exist.\n"
		ls -la /projects/rbbswbld-store/images/nightly/$branch-RGLinux/
		exit 1
	fi

	# RG
	if [ "$target" == "dcm" ]
	then
	    filename=ubifs-128k-2048-$chip-$target-RG.img
	else
	    filename=ubifs-128k-2048-$chip-RG.img
	fi
	cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename .
	if [ $? -ne 0 ]
	then
		ls -la /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date
		clean_up
		exit 1
	else
	    echo "cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename"
	    params[RG]=$filename
	    # Store the list of images created in this script so that they can be cleaned up.
	    files_to_delete=("${files_to_delete[@]}" $filename)
	fi

	# KERNEL
	if [ "$target" == "dcm" ]
	then
	    filename=vmlinuz-$chip-$target
	else
	    filename=vmlinuz-$chip
	fi

        cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename .
	if [ $? -ne 0 ]
	then
		ls -la /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date
		clean_up
		exit 1
	else
		echo "cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename"
		params[KERNEL]=$filename
		# Store the list of images created in this script so that they can be cleaned up.
		files_to_delete=("${files_to_delete[@]}" $filename)
	fi

        # DEVTREE
	if [ "$target" == "dcm" ]
	then
	    filename=rg.$chip-$target.dtb.tgz
	else
	    filename=rg.$chip.dtb.tgz
	fi

        cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename .
	if [ $? -ne 0 ]
	then
		ls -la /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date
		clean_up
		exit 1
	else
		echo "cp /projects/rbbswbld-store/images/nightly/$branch-RGLinux/$target_date/$filename"
		params[DEVTREE]=$filename
		# Store the list of images created in this script so that they can be cleaned up.
		files_to_delete=("${files_to_delete[@]}" $filename)
	fi

	if [ "$branch" == "develop" ]
	then
	    cmbranch=develop_d31
	    if [ "$target" != "dcm" ]
	    then
		cmbranch=$cmbranch-$cxc_version
	    fi
	else
	    if [ "$target" == "dcm" ]
	    then
		cmbranch=$branch-D31
	    else
		cmbranch=$branch-$cxc_version
	    fi
	fi

	# Check if a DOCSIS image name is specified by the user.
	if [ "$cm_filename" != "" ]
	then
	    filepath=/projects/rbbswbld-store/images/nightly/$cmbranch/$target_date/$cm_filename
	    [ -f $filepath ]
	    if [ $? -ne 0 ]
	    then
		    echo -e $"\n!!!ERROR!!!$filepath does not exist!\n"
		    echo -e $"!!!You MUST use -f option and SPECIFY the [ $target ] image from /projects/rbbswbld-store/images/nightly/$cmbranch/$target_date\n"
		    ls -la /projects/rbbswbld-store/images/nightly/$cmbranch/$target_date
		    clean_up
		    exit 1
	    fi
	else
	    # Figure out DOCSIS image file name based on target.
	    append=_fat.bin
	    filename=bcm93390$target
	    filepath=/projects/rbbswbld-store/images/nightly/$cmbranch/$target_date/$filename$append
	    echo "searching for $filename$append"
	    [ -f $filepath ]
	    if [ $? -ne 0 ]
	    then
		    #echo "$filepath does not exist"
		    append=_comcast_fat.bin
		    filename=bcm93390$target
		    filepath=/projects/rbbswbld-store/images/nightly/$cmbranch/$target_date/$filename$append
		    echo "searching for $filename$append"
		    [ -f $filepath ]
		    if [ $? -ne 0 ]
		    then
			#echo "$filepath does not exist"
			append=_comcast_virtnihal_fat.bin
			filename=bcm93390$target
			filepath=/projects/rbbswbld-store/images/nightly/$cmbranch/$target_date/$filename$append
			echo "searching for $filename$append"
			[ -f $filepath ]
			if [ $? -ne 0 ]
			then
			    echo -e $"\n!!!ERROR!!!$filepath does not exist!\n"
			    echo -e $"!!! You MUST use -f option and SPECIFY the [ $target ] image from /projects/rbbswbld-store/images/nightly/$cmbranch/$target_date\n"
			    ls -la /projects/rbbswbld-store/images/nightly/$cmbranch/$target_date
			    clean_up
			    exit 1
			fi
		    fi
	    fi
	fi

	cp $filepath ./cmrun1.bin
	if [ $? -ne 0 ]
	then
	    clean_up
	    exit 1
	else
	    echo "cp $filepath ./cmrun1.bin"
	fi
	# Create CM UBIFS
	cmubifs
	#params[DOCSIS]=cmrun1.bin
	params[CM]=ubifs-128k-2048-3390b0-CM.img
	# Store the list of images created in this script so that they can be cleaned up.
	files_to_delete=("${files_to_delete[@]}" "ubifs-128k-2048-3390b0-CM.img")

	# Create the param.txt file to pass into the create_monolith_rglinux script
	monolith_params_file=param.txt
	files_to_delete=("${files_to_delete[@]}" $monolith_params_file)

	for part in "${!params[@]}"
	do
		echo $part " : " ${params[$part]} >> $monolith_params_file
	done

	monolith=$branch-$chip$target-monolith-$target_date.bin
	if [ "$target" == "dcm" ]
	then
	    monolith=$branch-D31-$chip$target-monolith-$target_date.bin
	else
	    monolith=$branch-$cxc_version-$chip$target-monolith-$target_date.bin
	fi

	create_monolith_rglinux.sh -f $monolith_params_file -c $monolith_target -b $monolith

clean_up
