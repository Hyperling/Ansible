#!/bin/bash
# 2023-12-04 Hyperling
# Lower resolution of audio and convert to mp3. Also
# Also see: compress-video.sh

## Setup ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"
echo "Running '$DIR/$PROG'."

# Integers
typeset -i status

# Strings
typeset -l quality
quality="256k"
mp3="mp3"
tag="shrunk"
date_YYYYMMDD="`date "+%Y%m%d"`"
location="."
search="ls"
large_extension="DoNotUse-LargerThanOriginal"
large_created=".$PROG.large_created.true"

## Functions ##

function usage() {
	# Hit the user with knowledge on how to use this program.
	# Parameters:
	#   1) The exit status to use.
	status=$1
	echo -n "Usage: $PROG [-q QUALITY] [-l LOCATION] " >&2
	echo "[-A | [-r] [-f] [-d] [-c] [-z]] [-h] [-x]" >&2
	cat <<- EOF
		  Compress audio to mp3. Can handle folders and work recursively.

		Parameters:
		  -q QUALITY : Integer for the maximum length of either media dimension.
		  -l LOCATION : The specific media or folder which needs compressed.
		  -r : Recursively shrink media based on the location passed.
		  -f : Force the media to be shrunk even if a file already exists for it.
		  -d : Delete the original media if the compressed media is smaller.
		  -c : Clean the filename of underscores, dashes, 'IMG', etc.
		  -z : Convert from 440 to 432 Hz
		  -A : Resursively Force, Delete, and Clean.
		  -h : Display this usage text.
		  -x : Enable BASH debugging.
	EOF
	exit $status
}

## Parameters ##

while getopts ":q:l:rfdczAhx" opt; do
	case $opt in
		q) quality="$OPTARG" ;;
		l) location="$OPTARG" ;;
		r) recurse="Y" && search="find" ;;
		f) force="Y" ;;
		d) delete="Y" ;;
		c) clean="Y" ;;
		z) frequency="Y" ;;
		A) recurse="Y" &&
			search="find" &&
			force="Y" &&
			delete="Y" &&
			clean="Y" &&
			frequency="Y" ;;
		h) usage 0 ;;
		x) set -x ;;
		*) echo "ERROR: Option $OPTARG not recognized." >&2 && usage 1 ;;
	esac
done

## Validations ##

convert_exe="`which ffmpeg`"
if [[ "$convert_exe" == "" ]]; then
	echo "ERROR: 'ffmpeg' command could not be found, "
	echo "please install 'ffmpeg'."
	usage 2
fi

## Main ##

# If using ls, make sure full path is passed to the loop by adding '/*'.
if [[ -z "$recurse" && -d "$location" && "$location" != *'/*' ]]; then
	if [[ "$location" != *'/' ]]; then
		location="${location}/"
	fi
fi

settings="-ab $quality"
if [[ $frequency == "Y" ]]; then
	settings="$settings -af asetrate=44100*432/440,aresample=44100,atempo=440/432"
fi

$search "$location" | sort | while read media; do
	# Avoid processing directories no matter the name.
	[ -d "$media" ] && continue

	# Avoid processing files previously shrunk.
	[[ "$media" == *"$tag"* ]] && continue

	echo -e "\n$media"

	# Only look through mp3, m4a, flac, wav for now.
	typeset -l extension
	extension="${media##*.}"
	if [[ "$extension" != *"mp3"
		&& "$extension" != *"m4a"
		&& "$extension" != *"flac"
		&& "$extension" != *"wav" ]]
	then
		echo "  SKIP: Sorry, currently only mp3, m4a, flac, and wav are supported."
		continue
	fi

	new_media="${media//.$extension/}.$tag-$date_YYYYMMDD.$mp3"

	# Clean the filename of extra junk so that they can be chronological order.
	new_media_clean="$new_media"
	new_media_clean="${new_media_clean//_/ }"
	###new_media_clean="${new_media_clean//-/}"

	# Delete the existing shrunk media if we are forcing a new compression.
	if [[ -n "$force" && (-e "$new_media" || -e "$new_media_clean") ]]; then
		echo -n "  FORCE: "
		rm -v "$new_media" "$new_media_clean" 2>/dev/null
	fi

	# Skip if a compressed media was already created today.
	if [[ -e "$new_media" || -e "$new_media_clean" ]]; then
		echo "  SKIP: Media has already been shrunk previously, moving on."
		continue
	fi

	# Whether or not to use the cleaned version or the normal version.
	if [[ -n "$clean" ]]; then
		new_media="$new_media_clean"
	fi

	### TBD Instead of this, only alter the file names, and set a dirname var?
	# Create a new directory if the directory names were altered.
	mkdir -pv "`dirname "$new_media"`"

	# This modifies the media to be $size at its longest end, not be a square.
	$convert_exe -nostdin -hide_banner -loglevel quiet \
		-i "$media" $settings "$new_media"

	status="$?"
	if [[ "$status" != 0 ]]; then
		echo "  SKIP: '$convert_exe' returned a status of '$status'."
		continue
	fi

	# Check file sizes and if the new one is larger then flag it as large.
	echo "  Checking file sizes:"
	ls -sh "$media" "$new_media" | sort -hr | while read line; do
		echo "  $line"
	done
	smaller_file=`
		ls -sh "$media" "$new_media" | sort -h | cut -f 2- -d ' ' | head -n 1
	`
	if [[ "$smaller_file" == "$media" ]]; then
		echo -n "  WARNING: Conversion caused growth, original was likely lesser "
		echo "quality. Adding a suffix to the file to signify that it may be bad."
		echo -n "  "
		mv -v "$new_media" "$new_media.$large_extension"
		touch "$large_created"
		continue
	fi

	if [[ -e "$new_media" ]]; then
		echo "  SUCCESS: Conversion succeeded, file has been compressed."
	else
		echo "  ERROR: New media '$new_media' could not be found. Aborting."
		break;
	fi

	if [[ -n "$delete" ]]; then
		echo -n "  DELETE: "
		if [[ -d ~/TRASH ]]; then
			mv -v "$media" ~/TRASH/
		else
			rm -v "$media"
		fi
	fi
done

# If large files do end up being created, allow the user to bulk delete them.
if [[ -e "$large_created" ]]; then
	echo -e "\n*********************************************************"
	echo -e "WARNING: The files below are larger than their originals!\n"
	find "$location" -name "*"$large_extension
	echo -e "*********************************************************"

	echo -en "\nWould you like to delete them? (Y/n): "
	typeset -u confirm_delete
	read confirm_delete

	if [[ -z "$confirm_delete" || "$confirm_delete" == "Y"* ]]; then
		echo ""
		find "$location" -name "*"$large_extension -exec rm -v {} \;
	else
		echo -e "\nKeeping files. Please use this if you change your mind:"
		echo "  find \"$location\" -name \"*\"$large_extension -exec rm -v {} \;"
	fi

	rm "$large_created"
fi

echo -e "\nDone!"

exit 0
