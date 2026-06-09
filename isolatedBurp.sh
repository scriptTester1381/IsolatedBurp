#!/bin/bash

# Build latest version of Docker Image from Dockerfile
echo "Building Docker Image from Docker File..."
sleep 1
bash -c "docker build -t ubuntu-burp:latest ."
clear

# Ask user if they want to begin a fresh config file. Doing this will begin a new gold state and the user can re-enter their preferred settings.
echo -n "Fresh session configuration? [y/n]: "
sleep 1
read -r ans

# Purge script only executes if the user wants to start a fresh config file.
if [ $ans == "y" ]; then
	echo "Purging container cache..."
	sleep 1
	echo
	# Run the purge script as the current logged in user instead of root.
	bash -c "sudo -u $SUDO_USER sh IsolatedBurpSuiteSession/cachePurge.sh"
	echo "Cache Purged!"
	echo "IMPORTANT: Use /home/ubuntu/.BurpSuite/persistent_browser within the BurpSuite \"Burp's Browser\" settings. This will ensure configuration persistence."
	echo -n "Press enter to continue..."
	read
fi

# Begin main launcher script...
echo
echo "Launching container..."
sleep 1
bash -c "sh IsolatedBurpSuiteSession/main.sh"
