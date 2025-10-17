#!/bin/bash
# v1.0
# This script creates a .txt file named using a timestamp and saves it on the folder ~/Documents/journal

# Colors
GREEN='\e[32m'
BLUE='\e[34m'
RESET='\e[0m'

# Ensure the folder exists
mkdir ~/Documents/journal &> /dev/null

# Record current dir
CURR=$(pwd)

# Navigate into test folder
echo "Navigating to journal folder... "
cd ~/Documents/journal

# Declare name
name=$(date +%F)

# Allow user to choose between using positional arguments or without
# Use >> to allow multiple entries during the day
if [ -n "$1" ]; then
	echo "$1" >> "${name}".txt
	echo " "
	echo "------ Entry entered on: $(date) ------" >> ${name}.txt
	# feedback
	echo -e "${GREEN}Entry Successful!${RESET}" 
else
	read -p "Write entry: " ENT
	echo "${ENT}" >> "${name}".txt
	echo " "
	echo "------ Entry entered on: $(date) ------" >> ${name}.txt
	# feedback
	echo -e "${GREEN}Entry Successful!${RESET}"
fi

# Extra feedback
echo -e "${GREEN}Journal entry saved to ~/Documents/journal/${name}.txt${RESET}"

# Navigate back to working dir
echo
echo "Navigating back to your working directory... "
cd "${CURR}"
