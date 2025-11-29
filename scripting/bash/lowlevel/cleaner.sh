#!/bin/bash

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Use this to clean when running out of space
echo ""
echo -e "${GREEN}Checking what's hogging space...output in a few...${RESET}"
echo ""
echo -e "${YELLOW}---------- Top 20 hoggers -----------${RESET}"
echo ""
sudo du -xh / 2>/dev/null | sort -h | tail -n 20
echo ""
echo -e "${YELLOW}-------------------------------------${RESET}"
echo ""
echo -e "${GREEN}Doing safe cleaning...${RESET}"
echo ""
echo -e "${GREEN}Clearing browser(chrome) cache...${RESET}"
rm -rf ~/.cache/google-chrome/*
echo ""
echo -e "${GREEN}Clearing spotify cache...${RESET}"
rm -rf ~/.cache/spotify/*
echo ""
echo -e "${YELLOW}[*] Successfully cleared! Enjoy your space :)${RESET}"
