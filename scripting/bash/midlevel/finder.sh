#!/bin/bash
# v1.0
# This is the first script of the midlevel series
# Allows user to search for a file using the file name or extension, returning the full paths.
# Allows an extra option of saving logs to a log file

# Declare path variables
#LOG="$HOME/Documents/mylogs/$(date +%F).txt"
LOG="./finder_log_$(date +%F).txt"
DIR=${3:-$PWD}

# check if directory exists
if [[ -d "$DIR" ]]; then
	# The logic
	case $1 in
		"-n")
			PATTERN="$2"
			echo "Finding file..."
			echo " "
			find "$DIR" -type f -name "*$PATTERN*" | tee >( [[ $4 == "--log" ]] && tee -a "$LOG" )
			;;
		"-e")
			EXT="$2"
			echo "Finding file..."
			echo " "
			find "$DIR" -type f -name "*$EXT" | tee >( [[ $4 == "--log" ]] && tee -a "$LOG" )
			;;
		*)
			echo "Invalid flag. Usage: $0 [-n filename | -e extension] [opt: directory ] [ --log]"
			exit 1
			;;
	esac

else
	echo "$DIR does not exist. Try again."
	exit 1
fi
