#!/bin/bash
# v2.0
# Script number 3 in my lowlevel series
# This script prints a neat summary of system status
# echo -e "\e[31mThis text is red\e[0m" -> print colorful output using ANSI escape codes.

# Declare variables for formatting
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Declare variables for status checks
UPTIME=$(uptime -p)
USAGE=$(df -h / | awk 'NR==2 {print $5}')
MEM=$(free | awk '/Mem/{print int($3/$2 * 100)}')
LOAD=$(awk '{print $1}' /proc/loadavg)

# Check connectivity
if ping -c4 8.8.8.8 &> /dev/null; then
	STATUS=online
else
	STATUS=offline
fi

# The actual output
echo -e "${GREEN}====== SYSTEM STATUS ======${RESET}"
echo -e "Time: ${BLUE}$(date)${RESET}"
echo -e "User: ${GREEN}$(whoami)${RESET}"
echo -e "Hostname: ${GREEN}$(hostname)${RESET}"
echo -e "Uptime: ${GREEN}${UPTIME#'up '}${RESET}"
echo -e "Disk Usage: ${GREEN}${USAGE}${RESET}"

# Memory percentage customisation
if [[ ${MEM} -ge 80 ]]; then
	echo -e "Memory: ${RED}${MEM}% (High)${RESET}"
elif [[ ${MEM} -ge 50 ]]; then
	echo -e "Memory: ${YELLOW}${MEM}% (Moderate)${RESET}"
else
	echo -e "Memory: ${GREEN}${MEM}% (Low)${RESET}"
fi
# CPU load average
echo -e "CPU Load: ${GREEN}${LOAD}${RESET}"

# Extra flair for internet status
if [[ ${STATUS} = online ]]; then
	echo -e "Internet Status: ${GREEN}${STATUS}${RESET}"
else
	echo -e "Internet Status: ${RED}${STATUS}${RESET}"
fi

echo -e "${GREEN}===========================${RESET}"

### CORRECTIONS AND IMPROVEMENTS ###
# v1.0 got a rating of 8.7 from chatGPT and an 8 from Gemini :)
# 1. Instead of redirecting ping to a file named 1, redirect to /dev/null.
# 2. Replace use of $?(though effective), with an if clause, which is safer. $? could
# be overwritten by a background process.
# 3. Add CPU load average for an even cooler script :)
# 4. Add date and time for context.

## Some of the recommended improvements were to make the script more compatible with
# other systems. I didn't see the need since this will only be ran on mine predominantly.
