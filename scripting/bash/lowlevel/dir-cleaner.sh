#!/bin/bash
# My first ever bash project! Very excited! Hopefully I'll learn quite a bit over the course of this.
# This is a directory cleaner that organizes files in a folder by type and finds and replaces whitespaces
# in filenames.

# loop through the list of files and directories
for filename in $(ls); do
	# check for specific file extensions and move them to relevant Directories
	if [[ "$filename" == *.txt ]] || [[ "$filename" == *.pdf ]] || [[ "$filename" == *.odt ]]; then
		mv $filename ~/Documents/
	elif [[ "$filename" == *.png ]] || [[ "$filename" == *.jpeg ]]; then
		mv $filename ~/Pictures/
	else
		mv $filename ~/Videos/
	fi
done
