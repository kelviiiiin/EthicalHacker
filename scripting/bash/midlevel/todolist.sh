#!/bin/bash
# v2.0
# This script 4 of the midlevel series.
# It is a CLI To-Do list
# I am going to use sed for the text insertion and manipulation

# Color
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Create the dir and files for the todo list
mkdir -p "$HOME/Documents/todolist"
mkdir -p "$HOME/Documents/mylogs/todolist"
touch "$HOME/Documents/mylogs/todolist/todolist.log"
LOG="$HOME/Documents/mylogs/todolist/todolist.log"

# Create file(avoid recreating if it does exist)
FILE="$HOME/Documents/todolist/$(date +%F).txt"
touch "$FILE"

# The UI
echo " "
echo -e "${YELLOW}------------ CLI ToDo List ------------${RESET}"
echo " "

select TASK in "Add tasks" "List tasks" "Mark task as done" "Delete tasks" "Quit"
do
	case $TASK in
		"Add tasks")
			echo " "
			# Ask user input
			read -p "Enter the name of the task: " task
			echo " "
			
			# Get the number of existing lines in the file
			NLINES=$(wc -l < "$FILE")

			# The file title
			if [[ $NLINES == "0" ]]; then
				# Add date as first line of the list
				echo "-------- ToDo List --------" >> "$FILE"
				echo " " >> "$FILE"
				NLINES=0
			else
				# Remove the added deficit
				NLINES=$(($NLINES - 2))
			fi

			# Enter the task in file
			echo -e "$(($NLINES + 1)). "$task"" >> "$FILE"

			# Log activity
			echo "[$(date +'%F %H:%M')] Added task: $task - $FILE" >> "$LOG"
			echo " " >> "$LOG"

			# feedback
			echo " "
			echo -e "${GREEN}Task Successfully Added!${RESET}"
			echo " "
			;;
		"List tasks")
			echo " "
			# Ask for the date
			read -p "What is the date the requested list was created? [YYYY-MM-DD] " DATE

			if [[ -z "$DATE" ]]; then
				# Overwrite variable
				DATE=$(date +%F)
			fi

			# Find the file
			FILE=$(find "$HOME/Documents/todolist" -type f -name "$DATE.txt")
			sleep 1

			# feedback if no file found
			if [[ -z "$FILE" ]]; then
				echo " "
				echo -e "${RED}File not found.${RESET}"
				echo " "
				continue
			fi

			# File found
			echo " "
			echo -e "${GREEN}File found!${RESET}"

			# Output list
			echo " "
			cat "$FILE"
			echo " "
			echo -e "${YELLOW}-------- End of List --------${RESET}"
			echo " "
			;;
		"Mark task as done")
			echo " "
			# Ask user input to find specific file
			read -p "Enter the date of your list: [YYYY-MM-DD: today] " DATE

			# Check date
			if [[ -z "$DATE" ]]; then
				# Overwrite variable
				DATE=$(date +%F)
			fi

			# Find the file
			FILE=$(find "$HOME/Documents/todolist" -type f -name "$DATE.txt")
			sleep 1

			# feedback
			if [[ -z "$FILE" ]]; then
				echo " "
				echo -e "${RED}File does not exist.${RESET}"
				echo " "
				continue
			fi

			# Output the file contents
			echo " "
			echo -e "${YELLOW}Have a look at your list first: ${RESET}"
			echo " "
			cat "$FILE"
			echo " "
			echo -e "${YELLOW}-------- End of List --------${RESET}"
			echo " "

			# Ask for ID
			read -p "Enter the ID of the task you wanna mark as done: " ID
			echo " "

			# Capture task
			LINE_TASK=$(sed -n "/^$ID\./p" "$FILE")

			# Mark as done by appending text to the end of the task
			sed -i "/^$ID\./s/$/ -> Done at $(date +'%F %H:%M')/" "$FILE"

			# Log activity
			echo "[$(date +'%F %H:%M')] Completed $LINE_TASK - $FILE" >> "$LOG"
			echo " " >> "$LOG"

			# feedback
			echo -e "${GREEN}-------- Successfully Marked as Done --------${RESET}"
			echo " "
			echo -e "${YELLOW}A Post-Edit Review: ${RESET}"
			echo " "
			cat "$FILE"
			echo " "
			;;
		"Delete tasks")
			echo " "
			# Ask user input
			read -p "Enter the date of the todolist you want to delete the task from: [Default: today]" DATE
			if [[ -z "$DATE" ]]; then
				# Overwrite variable
				DATE=$(date +%F)
			fi
			
			# Find file
			echo " "
			echo -e "${GREEN}Searching for file...${RESET}"
			sleep 1
			FILE=$(find "$HOME/Documents/todolist" -type f -name "$DATE.txt")

			# feedback
			if [[ -z "$FILE" ]]; then
				echo " "
				echo -e "${RED}File does not exist.${RESET}"
				echo " "
				continue
			fi
			
			# Display file content
			echo " "
			echo -e "${GREEN}File found! Review Content: ${RESET}"
			echo " "
			cat "$FILE"
			echo " "
			echo -e "${YELLOW}-------- End of List ---------${RESET}"
			echo " "

			# Pick the task by ID
			read -p "Enter the ID of the task you wish to delete: " ID

			# Delete task
			echo " "
			echo -e "${YELLOW}Deleting selected task...${RESET}"
			sleep 1
			# Capture task before deletion
			TASK_LINE=$(sed -n "/^$ID\./p" "$FILE")
			sed -i "/^$ID\./d" "$FILE"

			# Corrected renumbering logic to preserve the entire task name, including spaces.
			# It skips the first two lines (header) and re-indexes all subsequent lines
			# that look like a task (start with a number followed by a period).
			awk 'NR > 2 {
				if ($0 ~ /^[0-9]+\./) {
					# Print the new line number (NR-2) followed by a dot and the rest of the
					# line, starting from the first space after the dot.
					sub(/^[0-9]+\.\s*/, "", $0);
					print (NR-2) ". " $0;
				} else {
					# Print any other lines (like empty lines) unchanged
					print $0;
				}
			} NR <= 2 {
				# Print the first two lines (header and empty line) unchanged
				print $0;
			}' "$FILE" > temp && mv temp "$FILE"
			
			# Log activity
			echo "[$(date +'%F %H:%M')] Deleted: $TASK_LINE - $FILE" >> "$LOG"
			echo " " >> "$LOG"
			# Feedback
			echo " "
			echo -e "${GREEN}If task exists, Successfully deleted.${RESET}"
			echo " "
			echo -e "${YELLOW}A Post-Edit Review: ${RESET}"
			echo " "
			cat "$FILE"
			echo " "
			;;
		"Quit")
			# feedback
			echo " "
			echo -e "${RED}Quiting...${RESET}"
			echo " "
			sleep 1
			break
			;;
	esac
done

### CORRECTIONS AND RECOMMENDATIONS ###
# v1.0 got a 8.7. I'm really happy with that considering I researched everything and
# thought of all the logic myself^^
# 1. Bug in log after deletion
# 2. Use anchors in sed to ensure it only matches the specific pattern
# 3. Repeated file finding(leaving that as is for now)
# 4. Menu loop exit
# 5. Task Number Consistency. Renumber automatically after each delete
# 6. I should probably start using functions and printf inplace of echo
