#!/bin/bash
# 2023-06-13 Hyperling
# Compress a video to good-enough quality for high quality streaming.

## Setup ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"
echo "Running '$DIR/$PROG'."

filename_flag='compressed'
date_YYYYMMDD="`date "+%Y%m%d"`"
large_extension='DoNotUse-LargerThanOriginal'
large_created=".$PROG.large_created.true"

## Functions ##

function usage {
	echo -n "Usage: $PROG [-i file/folder] [-v bitrate] [-a bitrate] [-c vcodec]"
	echo " [-r] [-f] [-d] [-m] [-V] [-x] [-h]"
	cat <<- EOF
		  Reduce the filesize of a video file to make it stream well. It also
		  helps with the file size for placing the file into a backup system.
		  Currently only set up for mp4 files.

		Parameters:
		  -i input : The input file or folder with which to search for video files.
		             If nothing is provided, current directory (.) is assumed.
		  -v bitrate : The video bitrate to convert to, defaults to 2000k.
		  -a bitrate : The audio bitrate to convert to, defaults to 192k.
		  -c vcodec : The video codec you'd like to use, such as libopenh264.
		  -r : Recurse the entire directory structure, compressing all video files.
		  -f : Force recompressing any files by deleting it if it already exists.
		  -d : Delete the original video if the compressed version is smaller.
		  -m : Measure the time it takes to compress each video and do the loop.
		  -V : Add verbosity, such as printing all the variable values.
		  -x : Set the shell's x flag to display every action which is taken.
		  -h : Display this help messaging.
	EOF
	exit $1
}

## Parameters ##

while getopts ":i:v:a:c:rfdmVxh" opt; do
	case $opt in
		i) input="$OPTARG"
			;;
		v) video_bitrate="-b:v $OPTARG"
			;;
		a) audio_bitrate="-b:a $OPTARG"
			;;
		c) codec="-vcodec $OPTARG"
			;;
		r) search_command="find"
			;;
		f) force="Y"
			;;
		d) delete="Y"
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
	video_bitrate="-b:v 2000k"
fi

if [[ -z "$audio_bitrate" ]]; then
	audio_bitrate="-b:a 192k"
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
		  delete='$delete'
		  time_command='$time_command'
		  verbose='$verbose'
		  set_x='$set_x'
		  filename_flag='$filename_flag'
		  date_YYYYMMDD='$date_YYYYMMDD'
		  SECONDS='$SECONDS'
	EOF
fi

SECONDS=0
$search_command "$input" | sort | while read file; do
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

	#### Convert spaces to underscores.
	###newfile="${newfile// /_}"
	###
	#### Ensure any directories that had spaces get recreated without them.
	###mkdir -pv "`dirname "$newfile"`"

	# More exception checks based on the new file.
	if [[ -e "$newfile" ]]; then
		if [[ "$force" == "Y" ]]; then
			echo "FORCE: Removing '$newfile'."
			rm -vf "$newfile"
		else
			echo "SKIP: Already has a compressed version ($newfile)."
			continue
		fi
	fi

	# Convert the file.
	echo "Converting to '$newfile'."
	$time_command bash -c "ffmpeg -nostdin -hide_banner -loglevel quiet \
			-i '$file' $video_bitrate $audio_bitrate \
			$vcodec -movflags +faststart '$newfile'"
	status="$?"
	if [[ "$status" != 0 ]]; then
		echo "SKIP: ffmpeg returned a status of '$status'."
		continue
	fi

	# Check the filesize compared to the original and note if it is larger.
	echo "Checking file sizes:"
	ls -sh "$file" "$newfile" | sort -hr
	smaller_file=`ls -sh "$file" "$newfile" | sort -h | cut -f 2- -d ' ' | head -n 1`
	if [[ "$smaller_file" == "$file" ]]; then
		echo -n "Conversion had the opposite effect, original was likely lesser "
		echo "quality. Adding a suffix to the file to signify that it grew."
		mv -v "$newfile" "$newfile.$large_extension"
		continue
	fi

	if [[ -e "$newfile" ]]; then
		echo "Conversion succeeded, file has been compressed."
	else
		echo "ERROR: Converted file '$newfile' could not be found. Aborting."
		break
	fi

	if [[ -n "$delete" ]]; then
		echo -n "Original has been deleted: "
		if [[ -d ~/TRASH ]]; then
			mv -v "$file" ~/TRASH/
		else
			rm -v "$file"
		fi
	fi
done

# If large files do end up being created, allow the user to bulk delete them.
if [[ -e "$large_created" ]]; then
	echo -e "\n*********************************************************"
	echo -e "WARNING: The files below are larger than their originals!\n"
	find "$input" -name "*"$large_extension
	echo -e "*********************************************************"

	echo -en "\nWould you like to delete them? (Y/n): "
	typeset -u confirm_delete
	read confirm_delete

	if [[ -z "$confirm_delete" || "$confirm_delete" == "Y"* ]]; then
		echo ""
		find "$input" -name "*"$large_extension -exec rm -v {} \;
	else
		echo -e "\nKeeping files. Please use this if you change your mind:"
		echo "  find \"$input\" -name \"*\"$large_extension -exec rm -v {} \;"
	fi

	rm "$large_created"
fi

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
