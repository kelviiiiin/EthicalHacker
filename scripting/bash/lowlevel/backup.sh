#!/bin/bash
# This is v2.0
# Second script in this series. It compresses a directory into a .tar.gz archive with a timestamp to its name.
read -p "Enter the complete name of the directory you want to compress: " DIR;

# current dir
PWD=$(pwd)

# clean $DIR for navigation
CLNDIR="${DIR/'~'/$HOME}"

# check if directory exists
if [[ -d "$CLNDIR" ]]; then
	# create backup directory
	mkdir -p  ~/Backups

	# navigate to target's parent
	echo "Navigating to the parent directory of the target..."
	cd $CLNDIR/..
	echo "$(pwd)"

	# remove leading "/" and "~"
	CDIR="${DIR#'~'}"
	CDIR="${CDIR#/}"

	# create the archive
	# use basename
	base=$(basename "$CDIR")
	tar -czf ~/Backups/${base}_backup_$(date +%F).tar.gz "$CLNDIR"

	# feedback
	echo "Backup created: ~/Backups/${base}_backup_$(date +%F).tar.gz"

	# navigate back to the working directory
	echo "Navigating back to your working dir..."
	cd $PWD
else
	echo "Directory "$DIR" does not exist. Enter a valid directory."
	exit 1
fi

## NOTES ##
# v1.0
# I've struggled with enabling the user to specify a path to the dir instead of having to run this script
# in the directory where the target is located.
#
# ChatGPT gave v1.0 a 8.5, Gemini gave it a 7. Not Bad.

## CORRECTIONS AND IMPROVEMENTS ##
# v2.0
# 1. mdir should use -p to suppress Error thrown
# 2. use parameter expansion to remove a single leading forwardslash, not all of them. ${DIR#/}. ${DIR%/} ->
# removes trailing.
# 3. Use basename instead of $CDIR in the name
