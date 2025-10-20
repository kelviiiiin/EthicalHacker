#!/bin/bash
# v2.0
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
echo -e "${YELLOW}╔════════════════════════════════════╗"
echo -e "║         WEBSITE UPTIME MONITOR     ║"
echo -e "╚════════════════════════════════════╝${RESET}"
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
URGENCY="normal" # options: low, normal, critical
EXPIRE_TIME="5000"

# Check if the positional argument "$1" is set
if [[ -z "$1" ]]; then
	# Get path to file with target sites
	read -p "Enter the path to the text file with the targets: " FILE
	echo " "
	
	# File input validation
	if [[ ! -f "$FILE" ]]; then
		echo -e "${RED}File not found!{RESET}"
		echo " "
		exit 1
	fi

	# Get targets from a file
	while IFS= read -r line; do
		# Get the returned code from the http header
		STATUS="$(curl -sL --max-time 20 -o /dev/null -w "%{http_code}" "$line")"

		# Check code
		if [[ "$STATUS" == "200" ]]; then
			# feedback
			echo -e "${GREEN}$line is up!${RESET}"
			# Keep count
			((UP++))

			# Add to log file
			echo " " >> "$LOG"
			echo -e "[$(date +'%F, %H:%M') "$line" - UP (200)" >> "$LOG"
			echo " " >> "$LOG"
		else
			# feedback
			echo -e "${RED}$line is down${RESET}"
			# Keep count
			((DOWN++))

			# Add to log file
			echo " " >> "$LOG"
			echo -e "[$(date +'%F, %H:%M') "$line" - DOWN ("$STATUS")" >> "$LOG"
			echo " " >> "$LOG"

			# The notification
			MESSAGE=""$line" is currently down!"
			notify-send -u "$URGENCY" -t "$EXPIRE_TIME" "$TITLE" "$MESSAGE"
		fi
	done < "$FILE"
else
	# "$1" is a URL
	# Get the returned code from the http header
	STATUS="$(curl -sL --max-time 20 -o /dev/null -w "%{http_code}" "$1")"
	
	# Check code
	if [[ "$STATUS" == "200" ]]; then
		# feedback
		echo -e "${GREEN}{$1} is up!${RESET}"
		# Keep count
		((UP++))

		# Add to log file
		echo " " >> "$LOG"
		echo -e "[$(date +'%F, %H:%M')] "$1" - UP (200)" >> "$LOG"
		echo " " >> "$LOG"
	else
		# feedback
		echo -e "${RED}${1} is down!${RESET}"
		# Keep count
		((DOWN++))

		# Add to log file
		echo " "
		echo -e "[$(date +'%F, %H:%M')] "$1" - DOWN ("$STATUS")" >> "$LOG"
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

### CORRECTIONS AND IMPROVEMENTS ###
# v1.0 got a 9(I'm only being graded by ChatGPT now on)
# 1. Check typos
# 2. Variable quoting consistency
# 3. Add file input validation
# 4. Add curl timeout of retry(so it's not stuck on unresponsive URLs)
# 5. Use a better logging format: [2022-10-14 14:32] https://example.com - UP (200)]
# 6. Could add Interval Monitoring(no need for now)
# 7. Flashier header ^^
