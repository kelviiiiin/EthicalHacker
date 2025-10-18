#!/bin/bash
# v2.0
# This is script 5 of the lowlevel series
# It tracks how long I've spent coding(or on any task) and logs it to a file
#
# Colors
GREEN='\e[32m'
RESET='\e[0m'

# Create logs directory at ~/Documents
mkdir -p "$HOME/Documents/mylogs"

# Declare path variables
LOG="$HOME/Documents/mylogs/$(date +%F).txt"
STFILE="$HOME/Documents/mylogs/.timer_start"

# The logic
case $1 in
	"start" | "Start")
		# Record task name for reference
		read -p "Enter task name: " TASK
		echo "$TASK" > "$HOME/Documents/mylogs/.task_name"

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
			# Calculate time taken using times since epoch
			seconds=$(($STOP - $START))

			# Duration in readable format
			minutes=$((($seconds % 3600)  / 60 ))
			hours=$(( $seconds / 3600 ))

			# Extract task name from .task_name file
			TASK=$(cat "$HOME/Documents/mylogs/.task_name")

			# Write to log file
			echo "$TASK completed in: $hours hours, $minutes minutes and $seconds seconds" >> "$LOG"
			echo " "
			
			echo -e "${GREEN}Log file for date: $(date +%F) created/updated successfully!${RESET}"
			echo " "
			# Feedback
			echo "Session Summary"
			echo "---------------"
			echo "Task: $TASK"
			echo "Duration: $hours hours, $minutes minutes and $seconds seconds"
			echo "Log saved to: $LOG"
			rm "$STFILE"
		else
			echo "No timer running."
		fi
		;;
	"show" | "Show")
		read -p "Enter the date of the log you wanna see: (YYYY-MM-DD)" DATE
		if [[ -f "$HOME/Documents/mylogs/$DATE.txt" ]]; then
			cat "$HOME/Documents/mylogs/$DATE.txt" 
		else
			echo "File does not exist"
		fi
		;;
	*)
		echo "Unknown input. Usage: $0 {start|stop|run}"
		;;
esac

### CORRECTIONS AND IMPROVEMENTS ###
# ChatGPT gave v1.0 a 9.2 :) and Gemini gave it a 7
# 1. Remove the redundant directory ~/Documents/startfile
# 2. Fix math inaccuracy
# 3. Fix the "show" command date format to match the files
# 4. Create a better task naming logic
# 5. Add a neat little summary at the end
