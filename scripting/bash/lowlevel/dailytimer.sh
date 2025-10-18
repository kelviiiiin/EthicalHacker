#!/bin/bash
# v1.0
# This is script 5 of the lowlevel series
# It tracks how long I've spent coding(or on any task) and logs it to a file
#
# Colors
GREEN='\e[32m'
RESET='\e[0m'

# Create logs directory at ~/Documents
mkdir -p "$HOME/Documents/mylogs"

# Clean storage of the start file
mkdir -p "$HOME/Documents/mylogs/startfile"

# Declare path variables
LOG="$HOME/Documents/mylogs/$(date +%F).txt"
STFILE="$HOME/Documents/mylogs/.timer_start"

# Record task name for reference
if [[ -n "$1" && ("$1" == "stop" || "$1" == "Stop") ]]; then
	read -p "What do you wanna name this task?  " TASK
fi

# The logic
case $1 in
	"start" | "Start")
		# Create and use start file
		echo "$(date +%s)" > "$STFILE"
		echo " "

		# start date in readable format
		START="$(date +"%F %I:%M:%S")"
		echo "Timer started on: ${START}"
		;;
	"stop" | "Stop")
		# Check if timer exists
		if [[ -f $STFILE ]]; then
			# Get start time
			START=$(cat $STFILE)

			# stop date in seconds since epoch
			STOP=$(date +%s)

			# stop date in readable format
			READSTOP="$(date +"%F %I:%M:%S")"
			echo "Timer stopped on: ${READSTOP}"
			echo " "
			# Calculate time taken using times since epoch
			seconds=$(($STOP - $START))

			# Duration in readable format
			minutes=$(( $seconds  / 60 ))
			hours=$(( $seconds / 3600 ))
			
			# Write to log file
			echo "$TASK completed in: $hours hours, $minutes minutes and $seconds seconds" >> "$LOG"
			echo " "
			# Feedback
			echo -e "${GREEN}Log file for date: $(date +%F) created/updated successfully!${RESET}"
			rm "$STFILE"
		else
			echo "No timer running."
		fi
		;;
	"show" | "Show")
		read -p "Enter the date of the log you wanna see: (DD-MM-YYYY)" DATE
		if [[ -f "$HOME/Documents/mylogs/$DATE.txt" ]]; then
			cat "$DATE.txt" 
		else
			echo "File does not exist"
		fi
		;;
	*)
		echo "Unknown input. Usage: $0 {start|stop|run}"
		;;
esac
