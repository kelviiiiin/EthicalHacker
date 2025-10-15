#!/bin/bash
# v1.0
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

# Check connectivity
ping -c4 8.8.8.8 &> 1

if [[ $? -eq 0 ]]; then
	STATUS=online
else
	STATUS=offline
fi

# The actual output
echo -e "${GREEN}====== SYSTEM STATUS ======${RESET}"
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

# Extra flair for internet status
if [[ ${STATUS} = online ]]; then
	echo -e "Internet Status: ${GREEN}${STATUS}${RESET}"
else
	echo -e "Internet Status: ${RED}${STATUS}${RESET}"
fi

echo -e "${GREEN}===========================${RESET}"
