#!/bin/bash
# Second script in this series. It compresses a directory into a .tar.gz archive with a timestamp to its name.
read -p "Enter the complete name of the directory you want to compress: " DIR;

# check if directory exists
if [[ -d "$DIR" ]]; then
	# create backup directory
	mkdir ~/Backups

	# remove trailing "/"
	CDIR=$(echo $DIR | tr -d '/')

	# create the archive
	tar -czvf ~/Backups/$CDIR-$(date +%F).tar.gz $DIR

	# feedback
	echo "Backup for $DIR created at ~/Backups"
else
	echo "Directory "$DIR" does not exist. Enter a valid directory."
	exit 0
fi

## NOTES ##
# v1.0
# I've struggled with enabling the user to specify a path to the dir instead of having to run this script
# in the directory where the target is located.
