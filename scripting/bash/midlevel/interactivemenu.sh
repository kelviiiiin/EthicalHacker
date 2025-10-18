#!/bin/bash
# v1.0
# This is script 2 of the midlevel series
# This outputs an interactive menu on the terminal that lets user perform a number of
# system or file related functions

# As a matter of convenience, continuity and to review lessons in lowlevel,
# I will use code from those scripts as the primary options for the user

# Thus, the options will be: view sysinfo, find a file, clean directory, and
# make a journal entry

# Colors
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
RESET='\e[0m'

PS3="Select the task you wish to perform: "

select TASK in "View System Info" "Clean a Directory" "Find a File"  "Make Journal Entry" "Quit"
do
	case "$TASK" in
		"View System Info")
			# Declare variables for status checks
			UPTIME=$(uptime -p)
			USAGE=$(df -h / | awk 'NR==2 {print $5}')
			MEM=$(free | awk '/Mem/{print int($3/$2 * 100)}')
			LOAD=$(awk '{print $1}' /proc/loadavg)

			# Check connectivity
			if ping -c4 8.8.8. &> /dev/null; then
				STATUS=online
			else
				STATUS=offline
			fi

			# The actual output
			echo " "
			echo -e "${GREEN}====== SYSTEM STATUS ======${RESET}"
			echo -e "Time: ${BLUE}$(date)${RESET}"
			echo -e "User: ${GREEN}$(whoami)${RESET}"
			echo -e "Hostname: ${GREEN}$(hostname)${RESET}"
			echo -e "Uptime: ${GREEN}${UPTIME#'up '}${RESET}"
			echo -e "Disk Usage: ${GREEN}${USAGE}${RESET}"

			# Memory Percentage customisation
			if [[ ${MEM} -ge 80 ]]; then
				echo -e "Memory: ${RED}${MEM} (High)${RESET}"
			elif [[ ${MEM} -ge 50 ]]; then
				echo -e "Memory: ${YELLOW}${MEM} (Moderate)${RESET}"
			else
				echo -e "Memory: ${GREEN}${MEM} (Low)${RESET}"
			fi
			# CPU load average
			echo -e "CPU Load: ${GREEN}${LOAD}${RESET}"
			
			# Extra flair for internet status
			if [[ ${STATUS} = online ]]; then
				echo -e "Internet Status: ${GREEN}${STATUS}${RESET}"
			else
				echo -e "Internet Status: ${RES}${STATUS}${RESET}"
			fi

			echo -e "${GREEN}===========================${RESET}"
			echo " "
			;;
		"Clean a Directory")
			# Ensure destination directories exist
			mkdir -p ~/Documents ~/Pictures ~/Videos ~/Others

			# Loop through the list of files and directories
			for filename in *; do
				# Skip directories
				[[ -d "$filename" ]] && continue

				# Replace spaces
				newname="${filename// /_}"
				if [[ "$filename" != "$newname" ]]; then
					mv "$filename" "$newname"
					# feedback
					echo "Renamed "$filename" to "$newname""
					filename="$newname"
				fi

				# check for specific file extensions and move them to relevant directories
				if [[ "$filename" == *.txt || "$filename" == *.pdf || "$filename" == *.odt ]]; then
					mv "$filename" ~/Documents/
					# feedback
					echo -e "${GREEN}Moved "$filename" to ~/Documents${RESET}"

				elif [[ "$filename" == *.png || "$filename" == *.jpeg || "$filename" == *.jpg ]]; then
					mv "$filename" ~/Pictures/
					# feedback
					echo -e "${GREEN}Moved "$filename" to ~/Pictures${RESET}"

				elif [[ "$filename" == *.mp4 || "$filename" == *.mkv ]]; then
					mv "$filename" ~/Videos/
					# feedback
					echo -e "${GREEN}Moved "$filename" to ~/Pictures${RESET}"

				else
					mv "$filename" ~/Others
					# feedback
					echo -e "${GREEN}Moved "$filename" to ~/Others${RESET}"
				fi
			done
			;;
		"Find a File")
			# Ask for the necessary variables from user
			echo "Enter details for the file you wanna find: "
			echo " "
			read -p "Which directory do you wish to search? " DIR
			read -p "Enter file pattern(can be an extension or the filename): " PATTERN
			read -p "Store this activity in a log file? [y/n]" LFILE
			# Ensure log dir exists
			mkdir -p "$HOME/Documents/mylogs"

			# Declare path variables
			LOG="$HOME/Documents/mylogs/finder_log_$(date +%F).txt"

			# For flexibility
			LOG_ENABLED=false

			# Check if directory exists
			if [[ -d "$DIR" ]]; then
				# Check if log is enabled
				if [[ "$LFILE" == "y" ]]; then
					LOG_ENABLED=true
				else
					LOG_ENABLED=false
				fi

				# The logic
				echo " "
				echo -e "${GREEN}Finding file(s)...${RESET}"
				echo " "
				find "$DIR" -type f -name "*$PATTERN*" | tee >( $LOG_ENABLED && tee -a "$LOG" )
				echo " "

				# Variable for results for later feedback
				RESULTS=$(find "$DIR" -type f -name "*$PATTERN*")

				# Feedback if no files found
				if [[ -z "$RESULTS" ]]; then
					echo "No files found matching ${PATTERN}"
				fi
			else
				echo -e "${YELLOW}$DIR does not exist. Try again.${RESET}"
				exit 1
			fi
			;;
		"Make Journal Entry")
			# Ensure the folder exists
			mkdir -p "$HOME/Documents/journal"
			
			# Record current dir
			CURR=$(pwd)

			# Navigate into journal folder
			echo " "
			echo -e "${YELLOW}Navigating into journal folder...${RESET}"
			echo " "
			cd ~/Documents/journal

			# Declare name
			name=$(date +%F)

			# User input
			# For neat spaces in the file
			echo " " >> "${name}.txt"
			read -p "Write entry: " ENT
			echo "${ENT}" >> "${name}.txt"
			echo " " >> "${name}.txt"
			echo " "
			
			# Feedback
			echo -e "${GREEN}------ Entry entered on: $(date) ------${RESET}" >> "${name}.txt"
			echo -e "${GREEN}Entry Successful!${RESET}"
			echo " "
			echo -e "${GREEN}Journal entry saved to ~/Documents/journal/${name}.txt${RESET}"
			echo " "

			# Offer to open the file after writing
			read -p "Would you like to view your entry? (y/n): " VIEW
			[[ $VIEW == [Yy]* ]] && less "${name}.txt"

			# Navigate back to working dir
			echo " "
			echo -e "${YELLOW}Navigating back to your working directory...${RESET}"
			echo " "
			cd "${CURR}"
			;;
		"Quit")
			echo " "
			echo -e "${RED}Quiting...${RESET}"
			break
			;;
		*)
			echo "Invalid selection. Please choose a number from the menu."
			;;
	esac
done

				

