#!/bin/bash
# My first ever bash project! Very excited, hopeful I'll learn quite a bit over the course of this.
# This is a directory cleaner, that organizes files in a folder by type and finds and replaces whitespaces
# in filenames.

DIR="."

# check if files exist in the current directory
for filename in $(ls); do
	if [[ "$filename" == *.txt ]]; then
		mv $filename ~/Documents/
	fi
done
