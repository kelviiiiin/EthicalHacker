#!/bin/bash
# v2.0
# This is the first script of the midlevel series
# Allows user to search for a file using the file name or extension, returning the full paths.
# Allows an extra option of saving logs to a log file

# Color
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Ensure log directory exists
mkdir -p "$HOME/Documents/mylogs"

# Declare path variables
LOG="$HOME/Documents/mylogs/finder_log_$(date +%F).txt"
DIR=${3:-$PWD}

# That flexibility fix
LOG_ENABLED=false

# check if directory exists
if [[ -d "$DIR" ]]; then
	# Check if log is enabled
	for arg in "$@"; do
		[[ $arg == "--log" ]] && LOG_ENABLED=true
	done

	# The logic
	case $1 in
		"-n")
			PATTERN="$2"
			echo -e "${GREEN}Finding file...${RESET}"
			echo " "
			find "$DIR" -type f -name "*$PATTERN*" | tee >( $LOG_ENABLED && tee -a "$LOG" )

			# Variable for results for later feedback
			RESULTS=$(find "$DIR" -type f -name "*$PATTERN*")
			;;
		"-e")
			EXT="$2"
			echo -e "${GREEN}Finding file...${RESET}"
			echo " "
			find "$DIR" -type f -name "*$EXT" | tee >( $LOG_ENABLED && tee -a "$LOG" )

			# Variable for results
			RESULTS=$(find "$DIR" -type f -name "*$EXT")
			;;
		*)
			echo "Invalid flag. Usage: $0 [-n filename | -e extension] [opt: directory ] [ --log]"
			exit 1
			;;
	esac

	# Feedback if no files found
	if [[ -z "$RESULTS" ]]; then
		echo "No files found matching $2"
	fi

else
	echo -e "${YELLOW}$DIR does not exist. Try again.${RESET}"
	exit 1
fi

### CORRECTIONS AND IMPROVEMENTS ###
# v1.0 got an 8.7 from ChatGPT
# 1. Logging argument position(maek it more flexible)
# 2. Add feedback for when no file found

