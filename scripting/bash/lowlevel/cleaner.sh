#!/bin/bash

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Use this to clean when running out of space
echo -e "\n${GREEN}Checking what's hogging space...output in a few...${RESET}\n"

echo -e "${YELLOW}---------- Top 20 hoggers -----------${RESET}\n"

sudo du -xh / 2>/dev/null | sort -h | tail -n 20

echo ""

echo -e "${YELLOW}-------------------------------------${RESET}\n"

echo -e "${GREEN}Doing safe cleaning...${RESET}\n"

echo -e "${GREEN}Chrome no longer exists :)...${RESET}\n"

rm -rf ~/.cache/google-chrome/*

echo -e "${GREEN}Clearing spotify cache...${RESET}\n"

rm -rf ~/.cache/spotify/*

echo -e "${YELLOW}[*] Successfully cleared! Have a look at all your new space! :)${RESET}\n"

df -h
