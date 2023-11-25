#!/bin/bash
# 2023-08-31 Hyperling
# Lower resolution of images for uploading to websites or keeping in storage.
# Also see: compress-video.sh

## Setup ##

DIR="$(dirname -- "${BASH_SOURCE[0]}")"
PROG="$(basename -- "${BASH_SOURCE[0]}")"
echo "Running '$DIR/$PROG'."

# Integers
typeset -i size status
size=2000

# Strings
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
	echo "Usage: $PROG [-s SIZE] [-l LOCATION] [-A | [-r] [-f] [-d] [-c]] [-h] [-x]" >&2
	cat <<- EOF
		  Compress JPG or PNG image(s). Can handle folders and work recursively.

		Parameters:
		  -s SIZE : Integer for the maximum length of either image dimension.
		  -l LOCATION : The specific image or folder which needs images shrunk.
		  -r : Recursively shrink images based on the location passed.
		  -f : Force the image to be shrunk even if a file already exists for it.
		  -d : Delete the original image if the compressed image is smaller.
		  -c : Clean the filename of underscores, dashes, 'IMG', etc.
		  -A : Resursively Force, Delete, and Clean.
		  -h : Display this usage text.
		  -x : Enable BASH debugging.
	EOF
	exit $status
}

## Parameters ##

while getopts ":s:l:rfdcAhx" opt; do
	case $opt in
		s) in_size="$OPTARG" && size="$in_size" ;;
		l) location="$OPTARG" ;;
		r) recurse="Y" && search="find" ;;
		f) force="Y" ;;
		d) delete="Y" ;;
		c) clean="Y" ;;
		A) recurse="Y" && search="find" && force="Y" && delete="Y" && clean="Y" ;;
		h) usage 0 ;;
		x) set -x ;;
		*) echo "ERROR: Option $OPTARG not recognized." >&2 && usage 1 ;;
	esac
done

## Validations ##

if [[ -n "$in_size" && "$size" != "$in_size" ]]; then
	echo "ERROR: Size value '$in_size' included non-integer characters." >&2
	usage 1
fi

convert_exe="`which convert`"
if [[ "$convert_exe" == "" ]]; then
	echo "ERROR: 'convert' command could not be found, "
	echo "please install 'imagemagick'."
	usage 2
fi

## Main ##

# If using ls, make sure full path is passed to the loop by adding '/*'.
if [[ -z "$recurse" && -d "$location" && "$location" != *'/*' ]]; then
	if [[ "$location" != *'/' ]]; then
		location="${location}/"
	fi
fi

$search "$location" | sort | while read image; do
	# Avoid processing directories no matter the name.
	[ -d "$image" ] && continue

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

	# Clean the filename of extra junk so that they can be chronological order.
	new_image_clean="${new_image//IMG/}"
	new_image_clean="${new_image_clean//_/}"
	new_image_clean="${new_image_clean//-/}"
	new_image_clean="${new_image_clean// /}"

	# Delete the existing shrunk image if we are forcing a new compression.
	if [[ -n "$force" && (-e "$new_image" || -e $new_image_clean) ]]; then
		echo -n "  FORCE: "
		rm -v "$new_image" "$new_image_clean" 2>/dev/null
	fi

	# Skip if a compressed image was already created today.
	if [[ -e "$new_image" || -e $new_image_clean ]]; then
		echo "  SKIP: Image has already been shrunk previously, moving on."
		continue
	fi

	# Whether or not to use the cleaned version or the normal version.
	if [[ -n $clean ]]; then
		new_image="$new_image_clean"
	fi

	### TBD Instead of this, only alter the file names, and set a dirname var?
	# Create a new directory if the directory names were altered.
	mkdir -pv "`dirname "$new_image"`"

	# This modifies the image to be $size at its longest end, not be a square.
	$convert_exe "$image" -resize ${size}x${size} "$new_image"
	status="$?"
	if [[ "$status" != 0 ]]; then
		echo "  SKIP: '$convert_exe' returned a status of '$status'."
		continue
	fi

	# Check file sizes and if the new one is larger then flag it as large.
	echo "  Checking file sizes:"
	ls -sh "$image" "$new_image" | sort -hr | while read line; do
		echo "  $line"
	done
	smaller_file=`
		ls -sh "$image" "$new_image" | sort -h | awk '{print $2}' | head -n 1
	`
	if [[ "$smaller_file" == "$image" ]]; then
		echo -n "  WARNING: Conversion caused growth, original was likely lesser "
		echo "quality. Adding a suffix to the file to signify that it may be bad."
		echo -n "  "
		mv -v "$new_image" "$new_image.$large_extension"
		touch "$large_created"
		continue
	fi

	if [[ -e "$new_image" ]]; then
		echo "  SUCCESS: Conversion succeeded, file has been compressed."
	else
		echo "  ERROR: New image '$new_image' could not be found. Aborting."
		break;
	fi

	if [[ -n "$delete" ]]; then
		echo -n "  DELETE: "
		if [[ -d ~/TRASH ]]; then
			mv -v "$image" ~/TRASH/
		else
			rm -v "$image"
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
