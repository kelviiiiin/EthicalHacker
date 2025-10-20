#!/bin/bash
# v1.0
# Script 3 in the midlevel series.
# Allows user to check whether a website is up

# Colors
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
RESET='\e[0m'

# Ensure directories exist
mkdir -p "$HOME/Documents/mylogs/webcheck"

# The path variables
LOG="$HOME/Documents/mylogs/webcheck/webcheck.log"

# The "UI"
echo " "
echo -e "${GREEN}======= WEBCHECKER IS RUNNING =======${RESET}"
echo " "
echo -e "${BLUE}Time: $(date +'%A, %d-%m: %H:%M')${RESET}"
echo " "
echo -e "${BLUE}Checking status(s)...${RESET}"
echo " "

# Keeping track of output
UP=0
DOWN=0

# Sending Desktop Notifications when a site is down
TITLE="Script Warning"
URGENCY="normal" # options: low, norma, critical
EXPIRE_TIME="5000"

# Check if the positional argument "$1" is set
if [[ -z "$1" ]]; then
	# Get path to file with target sites
	read -p "Enter the path to the text file with the targets: " FILE
	echo " "

	# Get targets from a file
	while IFS= read -r line; do
		# Get the returned code from the http header
		STATUS="$(curl -sL -o /dev/null -w "%{http_code}" "$line")"

		# Check code
		if [[ "$STATUS" == "200" ]]; then
			# feedback
			echo -e "${GREEN}$line is up!${RESET}"
			# Keep count
			((UP++))

			# Add to log file
			echo " " >> "$LOG"
			echo -e "${GREEN}$line was up at $(date +'%F, %H:%M')${RESET}" >> "$LOG"
			echo " " >> "$LOG"
		else
			# feedback
			echo -e "${RED}$line is down${RESET}"
			# Keep count
			((DOWN++))

			# Add to log file
			echo " " >> "$LOG"
			echo -e "${RED}$line was down at $(date +'%F, %H:%M')${RESET}" >> "$LOG"
			echo " " >> "$LOG"

			# The notification
			MESSAGE=""$line" is currently down!"
			notify-send -u "$URGENCY" -t "$EXPIRE_TIME" "$TITLE" "$MESSAGE"
		fi
	done < "$FILE"
else
	# "$1" is a URL
	# Get the returned code from the http header
	STATUS="$(curl -sL -o /dev/null -w "%{http_code}" "$1")"
	
	# Check code
	if [[ "$STATUS" == "200" ]]; then
		# feedback
		echo -e "${GREEN}"$1" is up!${RESET}"
		# Keep count
		((UP++))

		# Add to log file
		echo " " >> "$LOG"
		echo -e "${GREEN}"$1" was up at $(date +'%F, %H:%M')${RESET}" >> "$LOG"
		echo " " >> "$LOG"
	else
		# feedback
		echo -e "${RED}"$1" is down${RESET}"
		# Keep count
		((DOWN++))

		# Add to log file
		echo " "
		echo -e "${RED}"$1" was down at $(date +'%F, %M:%M')${RESET}" >> "$LOG"
		echo " " >> "$LOG"

		# The notification
		MESSAGE=""$1" is currently down!"
		notify-send -u "$URGENCY" -t "$EXPIRE_TIME" "$TITLE" "$MESSAGE"
	fi
fi

echo " "
echo -e "${GREEN}========= WEBCHECK COMPLETE =========${RESET}"
echo " "
echo -e "${GREEN}============== SUMMARY ==============${RESET}"
echo " "
echo -e "${YELLOW}Number of sites up: $UP${RESET}"
echo " "
echo -e "${RED}Number of sites down: $DOWN${RESET}"
echo " "
echo -e "${GREEN}================ END ================${RESET}"
