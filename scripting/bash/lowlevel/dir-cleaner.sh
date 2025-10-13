#!/bin/bash
# My first ever bash project! Very excited! Hopefully I'll learn quite a bit over the course of this.
# This is a directory cleaner that organizes files in a folder by type and finds and replaces whitespaces
# in filenames.

# Ensure destination directories exist
mkdir ~/Documents ~/Pictures ~/Videos ~/Others

# loop through the list of files and directories
for filename in *; do
	# skip directories
	[[ -d "$filename" ]] && continue
	
	# replace spaces
	newname="${filename// /_}"
	if [[ "$filename" != "$newname" ]]; then
		mv "$filename" "$newname"
		# feedback
		echo "Renamed "$filename" to "$newname""
		filename="$newname"
	fi

	# check for specific file extensions and move them to relevant Directories
	if [[ "$filename" == *.txt || "$filename" == *.pdf || "$filename" == *.odt ]]; then
		mv "$filename" ~/Documents/
		# feedback
		echo "Moved "$filename" to ~/Documents"

	elif [[ "$filename" == *.png  || "$filename" == *.jpeg ]]; then
		mv "$filename" ~/Pictures/
		# feedback
		echo "Moved "$filename" to ~/Pictures"

	elif [[ "$filename" == *.mp4 || "$filename" == *.mkv ]]; then
		mv "$filename" ~/Videos/
		# feedback
		echo "Moved "$filename" to ~/Videos"
	else
		mv "$filename" ~/Others
		echo "Moved "$filename" to ~/Others"
	fi
done


## CORRECTIONS ## -> First try got a 7.5/10 by ChatGPT, a 5 by Gemini!
# 1. Using $(ls) can cause issues with filenames containing spaces, tabs or newlines
# 2. Missing whitespace handling
# 3. When dealing with filenames, the $filename variable should be quoted, otherwise files with spaces would misbehave.
# 4. Add more specific checks to avoid everything else not checked from going to one folder: "/Videos"
# 5. Destination directories may not exist. Make sure they do.
# 6. Add user feedback on bash
