#!/bin/bash

# UBIFS logical eraseblock limit - increase this number if mkfs.ubifs complains
#
# for 93385VCM using 128MB NAND and smaller flash partitions, 2047 is too large
# causing the attach/mount operation to fail.  Override this # to 250 for those
# cases.
max_leb_cnt=2047
max_led_cnt_small_eb=250

function make_ubi_svm_img()
{
        pebk=$1
        page=$2

        peb=$(($1 * 1024))

        echo -e "\nCreating UBI image for SVM partition"

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

	#mkdir -p tmp

        out=$output_directory/"ubifs-${pebk}k-${page}-${target}-SVM.img"

        echo "Writing UBIFS SVM images image for ${pebk}kB erase, ${minmsg}..."

        mkfs.ubifs -U -r $target_directory -o tmp/ubifs1.img \
                -m $page -e $leb -c ${max_leb_cnt}

        vol_size=$(du -sk tmp/ubifs1.img | cut -f1)

        cat >> tmp/ubinize.cfg <<-EOF
        [boot-volume]
        mode=ubi
        image=tmp/ubifs1.img
        vol_id=1
        vol_size=${vol_size}KiB
        vol_type=dynamic
        vol_name=images
        vol_flags=autoresize
EOF
        ubinize -o tmp/ubi.img -m $page -p $peb tmp/ubinize.cfg

        mv tmp/ubi.img $out
        echo "    -> $out"
}

function show_help()
{
        echo "Usage: build_cm_images.sh"
        echo "Required args:"
        echo "-d <directory> [this is the directory that contains the images to be included in the filesystem]"
        echo "-t <platform_target> [this is the build target, i.e. 3390a0, 7145b0, etc]"
        echo "Optional args"
	echo "-o <output path for generated image, default is . (current directory)>"
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
while getopts "h?d:t:o:" opt; do
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
        esac
done

case "$target" in
"7145a0"| "7145b0"| "3390a0"| "3390b0")
	;;
*)
	echo "Unrecognized target: $target, exiting..."
	exit 1
	;;
esac

if [ -d "$target_directory" ]
then
	mkdir -p tmp
	make_ubi_svm_img 128 2048
	rm -rf tmp
else
	echo "Cannot find target directory!"
	exit 1
fi
