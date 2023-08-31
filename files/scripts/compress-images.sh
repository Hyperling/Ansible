#!/bin/bash
# 2023-08-31 Hyperling
# Lower resolution of images for uploading to websites or keeping in storage.
# Also see: compress-video.sh

## TBD/Goals/NeedsTested ##
# Get this to be a production-quality program.
# Allow recursion through the directory passed or current dir.
# Ensure the shrunk image is smaller than the original, otherwise rename.
# KISS, only have options if the feature should be optional, otherwise enforce.
###

## Setup ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"

# Integers
typeset -i size status
size=2000

# Strings
tag="shrunk"
location="."
search="ls"

## Functions ##

function usage() {
	# Hit the user with knowledge on how to use this program.
	# Parameters:
	#   1) The exit status to use.
	status=$1
	echo "Usage: $PROG [-s SIZE] [-l LOCATION] [-r] [-f] [-h] [-x]" >&2
	cat <<- EOF
		  Compress JPG or PNG image(s).

		Parameters:
		  -s SIZE : Integer for the maximum length of either image dimension.
		  -l LOCATION : The specific image or folder which needs images shrunk.
		  -r : Recursively shrink images based on the location passed.
		  -f : Force the image to be shrunk even if a file already exists for it.
		  -h : Display this usage text.
		  -x : Enable BASH debugging.
	EOF
	exit $status
}

## Parameters ##

while getopts ":s:l:rfhx" opt; do
	case $opt in
		s) in_size="$OPTARG" && size="$in_size" ;;
		l) location="$OPTARG" ;;
		r) search="find" ;;
		f) force="Y" ;;
		h) usage 0 ;;
		x) set -x ;;
		*) echo "ERROR: Option $OPTARG not recognized." >&2 && usage 1 ;;
	esac
done

## Validations ##

if [[ $size != $in_size ]]; then # No "" on purpose.
	echo "ERROR: Size value '$in_size' included non-integer characters." >&2
	usage 1
fi

## Main ##

$search $location | while read image; do
	# Avoid processing directories no matter the name.
	[ -d $image ] && continue

	# Only look through JPG and PNG for now.
	typeset -l extension
	extension="${image##*.}"
	if [[ "$extension" != *".jpg" && "$extension" != *".png" ]]; then
		echo "  ERROR: Sorry, currently only JPG and PNG are supported."
		usage 2
	fi

	echo $image

	newimage=${image//.$extension/}-$tag.$extension
	if [[ ("$image" == *"$tag"* && -z "$force") || -e "$newimage" ]]; then
		echo "  SKIP: Image has already been shrunk previously, moving on."
		continue
	fi

	# This modifies the image to be $size at its longest end, not be a square.
	convert $image -resize ${size}x${size} $newimage &&
		echo "  SUCCESS"
done

exit 0
