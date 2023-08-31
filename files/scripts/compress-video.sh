#!/bin/bash
# 2023-06-13 Hyperling
# Compress a video to good-enough quality for high quality streaming.

DIR=`dirname $0`
PROG=`basename $0`
if [[ "$DIR" == '.' ]]; then
	DIR=`pwd`
fi
echo "Running $DIR/$PROG"

## Functions ##

function usage {
	echo "Usage: $PROG [-i file/folder] [-v bitrate] [-a bitrate] [-c vcodec] [-r] [-f] [-m] [-V] [-x] [-h]"
	cat <<- EOF
		  Reduce the filesize of a video file to make it stream well. It also
		  helps with the file size for placing the file into a backup system.
		  Currently only set up for mp4 files.

		Parameters:
		  -i input : The input file or folder with which to search for video files.
		             If nothing is provided, current directory (.) is assumed.
		  -v bitrate : The video bitrate to convert to, defaults to 2000k.
		  -a bitrate : The audio bitrate to convert to, defaults to 128k.
		  -c vcodec : The video codec you'd like to use, such as libopenh264.
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

while getopts ":i:v:a:c:rfmVxh" opt; do
	case $opt in
		i) input="$OPTARG"
			;;
		v) video_bitrate="$OPTARG"
			;;
		a) audio_bitrate="$OPTARG"
			;;
		c) codec="-vcodec $OPTARG"
			;;
		r) search_command="find"
			;;
		f) force="Y"
			;;
		m) time_command="time -p"
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

if [[ "$set_x" == "Y" ]]; then
	set -x
fi

if [[ -z "$input" ]]; then
	echo "WARNING: Program was not passed an input. Using current directory."
	input="."
fi

if [[ -z "$video_bitrate" ]]; then
	video_bitrate="2000k"
fi

if [[ -z "$audio_bitrate" ]]; then
	audio_bitrate="128k"
fi

if [[ -z "$codec" ]]; then
	codec=""
fi

if [[ -z "$search_command" ]]; then
	search_command="ls"
fi

if [[ -z "$time_command" ]]; then
	time_command=""
fi

## Other Variables ##

filename_flag='compressed'
date_YYYYMMDD="`date "+%Y%m%d"`"

## Main ##

if [[ "$verbose" == "Y" ]]; then
	cat <<- EOF
		VERBOSE: Full list of variables.
		  input='$input'
		  video_bitrate='$video_bitrate'
		  audio_bitrate='$audio_bitrate'
		  codec='$codec'
		  search_command='$search_command'
		  force='$force'
		  time_command='$time_command'
		  verbose='$verbose'
		  set_x='$set_x'
		  filename_flag='$filename_flag'
		  date_YYYYMMDD='$date_YYYYMMDD'
		  SECONDS='$SECONDS'
	EOF
fi

SECONDS=0
$search_command $input | sort | while read file; do
	echo -e "\n$file"

	if [[ -n "$time_command" ]]; then
		date
	fi

	# Exception checks for the existing file.
	if [[ "$file" != *'.mp4' ]]; then
		echo "SKIP: Not an MP4."
		continue
	fi
	if [[ "$file" == *"$filename_flag"* ]]; then
		echo "SKIP: Input is already compressed."
		continue
	fi

	# Build the new filename to signify it is different than the original.
	extension="${file##*.}"
	newfile="${file//$extension/$filename_flag-$date_YYYYMMDD.$extension}"

	# Convert spaces to underscores.
	newfile="${newfile// /_}"

	# More exception checks based on the new file.
	if [[ -e "$newfile" ]]; then
		if [[ "$force" == "Y" ]]; then
			echo "FORCE: Removing $newfile."
			rm -vf "$newfile"
		else
			echo "SKIP: Already has a compressed version ($newfile)."
			continue
		fi
	fi

	# Convert the file.
	echo "Converting to $newfile."
	$time_command bash -c "ffmpeg -nostdin -hide_banner -loglevel quiet \
			-i '$file' -b:v $video_bitrate -b:a $audio_bitrate \
			$vcodec -movflags +faststart $newfile"

	# Check the filesize compared to the original and note if it is larger.
	echo "Checking file sizes:"
	ls -sh $file $newfile | sort -hr
	smaller_file=`ls -sh $file $newfile | sort -h | awk '{print $2}' | head -n 1`
	if [[ $smaller_file == $file ]]; then # Purposefully not using "" here.
		echo -n "Conversion had the opposite effect, original was likely lesser "
		echo "quality. Adding a suffix to the file to signify that it grew."
		mv -v $newfile $newfile.DoNotUse-LargerThanOriginal
	else
		echo "Conversion succeeded, file has been compressed."
	fi
done

echo -e "\nDone!"

# Display elapsed time
if [[ -n "$time_command" ]]; then
	date
	typeset -i hours minutes seconds
	hours=$(( SECONDS / 3600 ))
	minutes=$(( (SECONDS % 3600) / 60 ))
	seconds=$(( SECONDS % 60 ))
	echo "Loop Performance: ${hours}h ${minutes}m ${seconds}s"
fi

exit 0
