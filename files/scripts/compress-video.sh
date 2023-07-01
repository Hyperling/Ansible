#!/bin/bash
# 2023-06-13 Hyperling
# Compress a video to good-enough quality for high quality streaming.

DIR=`dirname $0`
PROG=`basename $0`
if [[ $DIR == '.' ]]; then
	DIR=`pwd`
fi
echo "Running $DIR/$PROG"

## Functions ##

function usage {
	echo "Usage: $PROG [-i file/folder] [-v bitrate] [-a bitrate] [-r] [-f] [-m] [-V] [-x] [-h]"
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
		  -m : Measure the time it takes to compress each video and do the loop.
		  -V : Add verbosity, such as printing all the variable values.
		  -x : Set the shell's x flag to display every action which is taken.
		  -h : Display this help messaging.
	EOF
	exit $1
}

## Parameters ##

while getopts ":i:v:a:rfmVxh" opt; do
	case $opt in
		i) input="$OPTARG"
			;;
		v) video_bitrate="$OPTARG"
			;;
		a) audio_bitrate="$OPTARG"
			;;
		r) search_command="find"
			;;
		f) force="Y"
			;;
		m) time_command="time"
			;;
		V) verbose="Y"
			;;
		x) set_x="Y"
			;;
		h) usage 0
			;;
		*) echo "ERROR: Option '$OPTARG' not recognized." >&2
			usage 1
			;;
	esac
done

if [[ $set_x == "Y" ]]; then
	set -x
fi

if [[ -z "$input" ]]; then
	echo "WARNING: Program was not passed an input. Using current directory."
	input='.'
fi

if [[ -z $video_bitrate ]]; then
	video_bitrate='2000k'
fi

if [[ -z $audio_bitrate ]]; then
	audio_bitrate='128k'
fi

if [[ -z $search_command ]]; then
	search_command=ls
fi

if [[ -z $time_command ]]; then
	time_command=""
fi

## Other Variables ##

filename_flag='compressed'
date_YYYYMMDD="`date "+%Y%m%d"`"

## Main ##

if [[ $verbose == "Y" ]]; then
	cat <<- EOF
		VERBOSE: Full list of variables.
		  input='$input'
		  video_bitrate='$video_bitrate'
		  audio_bitrate='$audio_bitrate'
		  search_command='$search_command'
		  force='$force'
		  time_command='$time_command'
		  verbose='$verbose'
		  set_x='$set_x'
	EOF
fi

$time_command $search_command $input | while read file; do
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
	newfile=${file//$extension/$filename_flag-$date_YYYYMMDD.$extension}

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
	$time_command ffmpeg -nostdin -hide_banner -loglevel quiet \
			-i $file -b:v $video_bitrate -b:a $audio_bitrate \
			-vcodec libopenh264 -movflags +faststart $newfile
done

exit 0
