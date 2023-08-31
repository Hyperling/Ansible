#!/bin/bash
# 2023 Hyperling
# Has existed on my Nextcloud since early 2023. Originally written to downsize
#   images for items to sell online, also started seeing use to compress the
#   size of archived photos. Will likely see improvements like recursion added.

mkdir -p shrink

ls *.jpg | while read image; do
	echo $image
	# This modifies the image to be 2000 at its longest end, not be a square.
	convert $image -resize 2000x2000 shrink/$image-shrunk.jpg
done
