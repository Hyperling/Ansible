#!/bin/bash
# 2023-08-31 Hyperling
# Lower resolution of images for uploading to websites or keeping in storage.
# Also see: compress-video.sh

## Setup ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"
echo "Running $DIR/$PROG"

# Integers
typeset -i size status
size=2000

# Strings
tag="shrunk"
date_YYYYMMDD="`date "+%Y%m%d"`"
location="."
search="ls"

## Functions ##

function usage() {
	# Hit the user with knowledge on how to use this program.
	# Parameters:
	#   1) The exit status to use.
	status=$1
	echo "Usage: $PROG [-s SIZE] [-l LOCATION] [-r] [-f] [-d] [-h] [-x]" >&2
	cat <<- EOF
		  Compress JPG or PNG image(s). Can handle folders and work recursively.

		Parameters:
		  -s SIZE : Integer for the maximum length of either image dimension.
		  -l LOCATION : The specific image or folder which needs images shrunk.
		  -r : Recursively shrink images based on the location passed.
		  -f : Force the image to be shrunk even if a file already exists for it.
		  -d : Delete the original image if the compressed image is smaller.
		  -h : Display this usage text.
		  -x : Enable BASH debugging.
	EOF
	exit $status
}

## Parameters ##

while getopts ":s:l:rfdhx" opt; do
	case $opt in
		s) in_size="$OPTARG" && size="$in_size" ;;
		l) location="$OPTARG" ;;
		r) recurse="Y" && search="find" ;;
		f) force="Y" ;;
		d) delete="Y" ;;
		h) usage 0 ;;
		x) set -x ;;
		*) echo "ERROR: Option $OPTARG not recognized." >&2 && usage 1 ;;
	esac
done

## Validations ##

if [[ -n "$in_size" && $size != $in_size ]]; then # No "" on purpose.
	echo "ERROR: Size value '$in_size' included non-integer characters." >&2
	usage 1
fi

## Main ##

# If using ls, make sure full path is passed to the loop by adding '/*'.
if [[ -z "$recurse" && -d "$location" && "$location" != *'/*' ]]; then
	if [[ "$location" != *'/' ]]; then
		location="${location}/"
	fi
	location="${location}*"
fi

$search $location | sort | while read image; do
	# Avoid processing directories no matter the name.
	[ -d $image ] && continue

	# Avoid processing files previously shrunk.
	[[ "$image" == *"$tag"* ]] && continue

	echo -e "\n$image"

	# Only look through JPG and PNG for now.
	typeset -l extension
	extension="${image##*.}"
	if [[ "$extension" != *"jpg"
		&& "$extension" != *"jpeg"
		&& "$extension" != *"png" ]]
	then
		echo "  SKIP: Sorry, currently only JPG and PNG are supported."
		continue
	fi

	new_image="${image//.$extension/}.$tag-$date_YYYYMMDD.$extension"

	# Delete the existing shrunk image if we are forcing a new compression.
	if [[ -n "$force" && -e "$new_image" ]]; then
		echo -n "  FORCE: "
		rm -v "$new_image"
	fi

	# Skip if a compressed image was already created today.
	if [[ -e "$new_image" ]]; then
		echo "  SKIP: Image has already been shrunk previously, moving on."
		continue
	fi

	# This modifies the image to be $size at its longest end, not be a square.
	convert $image -resize ${size}x${size} $new_image

	# Check file sizes and if the new one is larger then flag it as large.
	echo "  Checking file sizes:"
	ls -sh $image $new_image | sort -hr | while read line; do
		echo "  $line"
	done
	smaller_file=`ls -sh $image $new_image | sort -h | awk '{print $2}' | head -n 1`
	if [[ $smaller_file == $image ]]; then # Purposefully not using "" here.
		echo -n "  WARNING: Conversion caused growth, original was likely lesser "
		echo "quality. Adding a suffix to the file to signify that it may be bad."
		echo -n "  "
		mv -v $new_image $new_image.DoNotUse-LargerThanOriginal
		continue
	fi

	echo "  SUCCESS: Conversion succeeded, file has been compressed."

	if [[ -n "$delete" ]]; then
		echo -n "  DELETE: "
		rm -v $image
	fi
done

echo -e "\nDone!"

exit 0
