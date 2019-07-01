#!/bin/bash

# UBIFS logical eraseblock limit - increase this number if mkfs.ubifs complains
#
# for 93385VCM using 128MB NAND and smaller flash partitions, 2047 is too large
# causing the attach/mount operation to fail.  Override this # to 250 for those
# cases.
max_leb_cnt=2047
max_led_cnt_small_eb=250
# Volume size (in erase blocks)
min_eb_per_vol=18

SCRIPT_NAME=`basename $0`
MANIFEST_FILE=$SCRIPT_NAME.manifest

function calculate_volume_size()
{
	contentsize=$2
	requiredsize=$(($min_eb_per_vol * $1))
	echo "Required Size: $requiredsize kBytes Content Size: $contentsize kBytes"
	if [ $contentsize -lt $requiredsize ]
	then
		#pad to leave room to write
		correctedvolsize=$(( ($requiredsize * 5) / 4))
	else
		correctedvolsize=$(( ($contentsize * 5) / 4))
	fi
	echo "Enlarging volume to $correctedvolsize kBytes"
}

function make_ubi_cm_img()
{
	pebk=$1
	page=$2

	peb=$(($1 * 1024))

	if ls $target_directory/cm* >& /dev/null; then
	    echo -e "\nCreating UBI rootfs image for CM partition"
	else
	    echo -e "\nWARNING: No files in $target_directory. CM images will not be created"
	    return
	fi

	if [ $pebk -eq 128 ]; then
		max_leb_cnt=$max_led_cnt_small_eb
	fi

	if [ $page -lt 64 ]; then
		leb=$(($peb - 64 * 2))
		minmsg="minimum write size $page (NOR)"
	else
		leb=$(($peb - $page * 2))
		minmsg="minimum write size $page (NAND)"
	fi

	out=$output_directory/"${prepend_prefix}ubifs-${pebk}k-${page}-${target}-CM.img"

	rm -f tmp/ubinize.cfg

	echo "Writing UBIFS CM images for ${pebk}kB erase, ${minmsg}..."

	rm -rf img_tmp
	mkdir -p img_tmp

	[ -f $target_directory/cmboot.bin ]
	if [ $? -ne 0 ]
	then
	    echo "Failed to find cmboot.bin. Exiting!"
	    rm -rf img_tmp
	    exit 1
	fi

	[ -f $target_directory/cmrun0.bin ] && cp $target_directory/cmrun0.bin img_tmp
	[ -f $target_directory/cmrun1.bin ] && cp $target_directory/cmrun1.bin img_tmp
	[ -f $target_directory/cmboot.bin ] && cp $target_directory/cmboot.bin img_tmp

	mkfs.ubifs -U -r img_tmp -o tmp/ubifs1.img \
		-m $page -e $leb -c ${max_leb_cnt}

	vol_size=$(du -sk tmp/ubifs1.img | cut -f1)
	calculate_volume_size $pebk $vol_size

	cat >> tmp/ubinize.cfg <<-EOF
	[boot-volume]
	mode=ubi
	image=tmp/ubifs1.img
	vol_id=1
	vol_size=${correctedvolsize}KiB
	vol_type=dynamic
	vol_name=images
	vol_flags=autoresize
EOF

	ubinize -o tmp/ubi.img -m $page -p $peb tmp/ubinize.cfg

	mv tmp/ubi.img $out
	echo "    -> $out"
        echo $out > $MANIFEST_FILE
	rm -rf img_tmp
}

function show_help()
{
        echo "Usage: build_cm_images.sh"
        echo "Required args:"
        echo "-d <directory> [this is the directory that contains the images to be included in the filesystem]"
        echo "-t <platform_target> [this is the build target, i.e. 3390a0, 7145b0, etc]"
        echo "Optional args"
	echo "-o <output path for generated image, default is . (current directory)>"
	echo "-p <prepend output file prefix ...warning initrd will not use>"
        echo "-h or ? [show this help]"
}

if [ $# -eq 0 ]
then
        show_help
        exit 1
fi

target_directory=
target=
output_directory="."

#we need a directory and a target from the user
while getopts "h?d:t:o:p:" opt; do
        case "$opt" in
        h|\?)
                show_help
                exit 0
                ;;
        d)  target_directory=$OPTARG
                ;;
        t)  target=$OPTARG
                ;;
        o)  output_directory=$OPTARG
                ;;
       p)  prepend_prefix=$OPTARG
	dash="-"
	prepend_prefix=$prepend_prefix$dash
                ;;
        esac
done

case "$target" in
"7145a0"| "7145b0"| "3384b0" | "3390a0"| "3390b0")
	;;
*)
	echo "Unrecognized target: $target, exiting..."
	exit 1
	;;
esac

if [ -d "$target_directory" ]
then
	mkdir -p tmp
	make_ubi_cm_img 128 2048
	rm -rf tmp
else
	echo "Cannot find target directory!"
	exit 1
fi
