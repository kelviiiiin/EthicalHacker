#!/bin/bash
# v2.0
# This script creates a .txt file named using a timestamp and saves it on the folder ~/Documents/journal

# Colors
GREEN='\e[32m'
BLUE='\e[34m'
RESET='\e[0m'

# Ensure the folder exists. -p ensures it wont throw and error if the dir exists
mkdir -p "$HOME/Documents/journal "

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
	echo "$1" >> "${name}.txt"
	echo " "
else
	read -p "Write entry: " ENT
	echo "${ENT}" >> "${name}.txt"
	echo " "
fi

# This was the redundant code
echo "------ Entry entered on: $(date) ------" >> "${name}.txt"
echo -e "${GREEN}Entry Successful!${RESET}"
echo " "

# Extra feedback
echo -e "${GREEN}Journal entry saved to ~/Documents/journal/${name}.txt${RESET}"
echo " "

# Connectivity or Version Flair -> Cause I wanna see how the code works
echo -e "${BLUE}Journal entry logged on $(date +"%A, %B %d, %Y at %I:%M %p")${RESET}"
echo " "

# Offer to open the file after writing
read -p "Would you like to view your entry? (y/n): " VIEW
[[ $VIEW == [Yy]* ]] && less "${name}.txt"

# Navigate back to working dir
echo " "
echo "Navigating back to your working directory... "
cd "${CURR}"

## CORRECTIONS AND IMPROVEMENTS ##
# ChatGPT gave v1.0 an 8.8 while Gemini gave it a 7
# 1. Safer directory creation(I think I've had this issue before:()
# 2. Quote ALL variables.
# 3. Simplify redundant code
