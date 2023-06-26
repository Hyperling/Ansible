#!/bin/bash
# 2023-06-13 Hyperling
# Compress a video to good-enough quality for high quality streaming.

DIR=`dirname $0`
PROG=`basename $0`
if [[ $DIR == '.' ]]; then
	DIR=`pwd`
fi
echo "Running $DIR/$PROG"

## Functions
function usage {
	cat <<- EOF 
		Reduce the filesize of a video file to make it stream well. It also
		  helps with the file size for placing the file into a backup system.
		  Currently only set up for libopenh264 and mp4 files.
		
		Parameters:
		  -i input : The input file or folder with which to search for video files. 
		             If nothing is provided, current directory (.) is assumed.
		  -v bitrate : The video bitrate to convert to, defaults to 2000k.
		  -a bitrate : The audio bitrate to convert to, defaults to 128k.
		  -r : Recurse the entire directory structure, compressing all video files.
		  -f : Force recompressing any files by deleting it if it already exists.
		  -h : Display this help messaging.
	EOF
	exit $1
}

## Parse Input
while getopts ":i:v:a:rfh" opt; do
	case $opt in
		i) input="$OPTARG"
			echo "input='$input'"
			;;
		v) video_bitrate="$OPTARG"
			echo "video_bitrate='$video_bitrate'"
			;;
		a) audio_bitrate="$OPTARG"
			echo "audio_bitrate='$audio_bitrate'"
			;;
		r) recurse="Y"
			search_command=find
			echo "recurse='$recurse', search_command='$search_command'"
			;;
		f) force="Y"
			echo "force='$force'"
			;;
		h) usage 0
			;;
	esac
done

if [[ -z "$input" ]]; then
	if [[ ! -z "$1" ]]; then
		echo "WARNING: Program was not passed a file. Using input $1."
		input=$1
	else
		echo "WARNING: Program was not passed a file. Using current directory."
		input='.'
	fi
fi

if [[ -z $video_bitrate ]]; then
	video_bitrate='2000k'
fi

if [[ -z $audio_bitrate ]]; then
	audio_bitrate='128k'
fi

if [[ -z $recurse ]]; then
	search_command=ls
fi

## Other Variables
filename_flag='compressed.'

## Main Loop
$search_command $input | while read file; do
	echo -e "\n$file"

	# Exception checks for the existing file.
	if [[ $file != *'.mp4' ]]; then
		echo "SKIP: Not an MP4."
		continue
	fi
	if [[ $file == *"$filename_flag"* ]]; then
		echo "SKIP: Input is already compressed."
		continue
	fi

	# Build the new filename to signify it is different thn the original.
	extension=${file##*.}
	newfile=${file//$extension/$filename_flag$extension}

	# More exception checks based on the new file.
	if [[ -e $newfile ]]; then
		if [[ $force == "Y" ]]; then
			echo "FORCE: Removing $newfile."
			rm -vf $newfile
		else
			echo "SKIP: Already has a compressed version ($newfile)."
			continue
		fi
	fi

	# Convert the file.
	echo "Converting to $newfile."
	ffmpeg -nostdin -hide_banner -loglevel quiet \
			-i $file -b:v $video_bitrate -b:a $audio_bitrate \
			-vcodec libopenh264 -movflags +faststart $newfile
done

exit 0
