#!/bin/bash
# v1.0
# This is script 5 of the midlevel series.
#
# Variables for the package manager check
APT=$(which apt)
DNF=$(which dnf)
PACMAN=$(which pacman)
PM=0 # The package manager

# Set the package manager
if [[ -n "$APT" ]]; then
	PM="apt"
elif [[ -n "$DNF" ]]; then
	PM="dnf"
elif [[ -n "$PACMAN" ]]; then
	PM="pacman"
else
	printf "\e[1;31mNone of the supported package managers exists.\e[0m\n"
	printf " "
	exit 1
fi

for COMMAND in $@; do
	# Check if tool already installed
	CHECK=$(which $COMMAND)
	
	if [[ -z "$CHECK"  ]]; then
		echo "$COMMAND not yet installed."
		# What's the PM?
		if [[ "$PM" == "apt" ]]; then
			# The installation
			sudo apt install -y $COMMAND
	else
		echo " "
		printf "\e[1;31m$COMMAND is already installed.\e[0m\n"
		echo " "
	fi
done
	

