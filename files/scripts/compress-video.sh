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
		
		Parameters:
		  -f input : The input file or folder with which to search for video files. 
		             If nothing is provided, current directory (.) is assumed.
		  -v bitrate : The video bitrate to convert to, defaults to 2000k.
		  -a bitrate : The audio bitrate to convert to, defaults to 128k.
		  -h : Display this help messaging.
	EOF
	exit $1
}

## Parse Input
while getopts ":f:v:a:h" opt; do
	case $opt in
		f) 
			input="$OPTARG"
			;;
		v) 
			video_bitrate="$OPTARG"
			;;
		a) 
			audio_bitrate="$OPTARG"
			;;
		h) 
			usage 0
			;;
	esac
done

if [[ -z $input && ! -z $1 ]]; then
	echo "WARNING: Program was not passed a file. Using input 1."
	input=$1
else
	echo "WARNING: Program was not passed a file. Using current directory."
	input='.'
fi

if [[ -z $video_bitrate ]]; then
	video_bitrate='2000k'
fi

if [[ -z $audio_bitrate ]]; then
	audio_bitrate='128k'
fi

## Other Variables
filename_flag='compressed.'

## Main Loop
ls $input | while read file; do
	## Exception Checks
	if [[ $file != *'.mp4' && $file != *'.mpeg' ]]; then
		echo "Skipping $file, not an MP4 or MPEG."
		continue
	fi

	# Build the new filename to signify it is different thn the original.
	extension=${file##*.}
	newfile=${file//$extension/$filename_flag$extension}

	if [[ $file == *"$filename_flag"* || -e $newfile ]]; then
		echo "Skipping $file, already compressed."
		continue
	fi

	# Convert the file.
	echo "Converting $file to $newfile."
	ffmpeg -nostdin -hide_banner -loglevel quiet \
			-i $file -b:v $video_bitrate -b:a $audio_bitrate \
			$newfile
done

exit 0