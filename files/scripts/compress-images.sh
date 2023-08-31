#!/bin/bash
# 2023-08-31 Hyperling
# Lower resolution of images for uploading to websites or keeping in storage.
# Also see: compress-video.sh

size=2000

ls *.jpg | while read image; do
	echo $image
	# This modifies the image to be $size at its longest end, not be a square.
	convert $image -resize ${size}x${size} ${image//.jpg/}-shrunk.jpg
done
