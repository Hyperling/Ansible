#!/bin/bash
# 2023-08-31 Hyperling
# Lower resolution of images for uploading to websites or keeping in storage.
# Also see: compress-video.sh

## TBD/Goals ##
# Get this to be a production-quality program.
# Allow recursion through the directory passed or current dir.
# Ensure the shrunk image is smaller than the original, otherwise rename.
# KISS, only have options if the feature should be optional, otherwise enforce.
###

## Setup ##

PROG="$(basename -- "${BASH_SOURCE[0]}")"
DIR="$(dirname -- "${BASH_SOURCE[0]}")"

size=2000
tag=shrunk

## Functions ##


## Parameters ##


## Validations ##


## Main ##

ls *.jpg | while read image; do
	echo $image
	newimage=${image//.jpg/}-$tag.jpg
	# This modifies the image to be $size at its longest end, not be a square.
	convert $image -resize ${size}x${size} $newimage
done

exit 0
