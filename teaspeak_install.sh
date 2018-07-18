#!/bin/bash

INSTALLER_VERSION="1.3"
INSTALLER_REPO_URL="https://api.github.com/repos/Sporesirius/TeaSpeak-Installer/releases/latest"
TEASPEAK_VERSION=$(curl -s -S -k https://repo.teaspeak.de/latest)
REQUEST_URL="https://repo.teaspeak.de/server/linux/x64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz"

function whiteMessage {
    echo -e "\\033[0;37m${@}\033[0m"
}

function greenMessage {
    echo -e "\\033[32;1m${@}\033[0m"
}

function cyanMessage {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage {
	echo -e "\\033[33;1m${@}\033[0m"
}

function purpleMessage {
    echo -e "\\033[0;35m${@}\033[0m"
}

function blueMessage {
    echo -e "\\033[0;34m${@}\033[0m"
}

function errorAndQuit {
    errorAndExit "Exit now!"
}

function errorAndExit {
    redMessage ${@}
    exit 0
}

function errorAndContinue {
    redMessage "Invalid option."
    continue
}

function greenOkAndSleep {
    greenMessage $1
    sleep 1
}

function yellowOkAndSleep {
    yellowMessage $1
    sleep 1
}

function checkInstall {
    if [ "`dpkg-query -s $1 2>/dev/null`" == "" ]; then
        greenOkAndSleep "Installing package $1"
        apt-get install -y $1
	else
		yellowOkAndSleep "Package $1 already installed. Skip!"
    fi
}

cyanMessage ""
redMessage "        TeaSpeak Installer"
cyanMessage ""

# We need to be root to install and update
if [ "`id -u`" != "0" ]; then
    errorAndExit "Root account is required to run the install script!"
fi

cyanMessage "Checking for the latest installer version..."
LATEST_VERSION=`wget -q --timeout=60 -O - ${INSTALLER_REPO_URL} | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)'`

if [ "`printf "${LATEST_VERSION}\n${INSTALLER_VERSION}" | sort -V | tail -n 1`" != "$INSTALLER_VERSION" ]; then
    errorAndExit "New version available. Please upgrade to version ${LATEST_VERSION} and retry."
else
    greenOkAndSleep "# You are using the up to date version ${INSTALLER_VERSION}."
fi

# Debian and its derivatives store their version at /etc/debian_version
if [ -f /etc/debian_version ]; then

	cyanMessage " "
	OS=`lsb_release -i 2> /dev/null | grep 'Distributor' | awk '{print($3)}'`
	
	if [ "$OS" == "" ]; then
		errorAndExit "Error: Could not detect OS. Currently only Debian and Ubuntu are supported.. Sry!"
	else
		greenOkAndSleep "$OS detected."
	fi

    greenOkAndSleep "# Updating the system packages..."
    apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
	greenOkAndSleep "DONE!"
	
	cyanMessage " "
	greenOkAndSleep "# Installing necessary TeaSpeak and Installer packages..."
	checkInstall curl
	checkInstall wget
	checkInstall tar
	checkInstall screen
	checkInstall ffmpeg
	checkInstall youtube-dl
	greenOkAndSleep "DONE!"
	
	cyanMessage " "
	cyanMessage "Please enter the name of the TeaSpeak user."
	read teaUser
	
	cyanMessage " "
	cyanMessage "Please enter the TeaSpeak installation path."
	cyanMessage "Empty input = /home/ | Example input = /srv/"
	read teaPath
	
	groupadd $teaUser
	if [ "$teaPath" == "" ]; then
		useradd -m -b /home -s /bin/bash -g $teaUser $teaUser
		cd /home/$teaUser/
	else
		mkdir -p /$teaPath
		useradd -m -b /$teaPath -s /bin/bash -g $teaUser $teaUser
		cd /$teaPath/$teaUser/
	fi
	
    cyanMessage " "
    cyanMessage "Create key or set password for login?"
    cyanMessage "Safest way of login is a password protected key."
	
    OPTIONS=("Create key" "Set password" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            3 ) errorAndQuit;;
            *) errorAndContinue;;
        esac
    done

    if [ "$OPTION" == "Create key" ]; then

        if [ -d /home/$teaUser/.ssh ]; then
            rm -rf /home/$teaUser/.ssh
        elif [ -d /$teaPath/$teaUser/.ssh ]; then
            rm -rf /$teaPath/$teaUser/.ssh
        fi

		if [ "$teaPath" == "" ]; then
			mkdir -p /home/$teaUser/.ssh
			chown $teaUser:$teaUser /home/$teaUser/.ssh
			cd /home/$teaUser/.ssh
		else
			mkdir -p /$teaPath/$teaUser/.ssh
			chown $teaUser:$teaUser /$teaPath/$teaUser/.ssh
			cd /$teaPath/$teaUser/.ssh
		fi

        cyanMessage " "
        cyanMessage "It is recommended but not required to set a password"
        su -c "ssh-keygen -t rsa" $teaUser

        KEYNAME=`find -maxdepth 1 -name "*.pub" | head -n 1`

        if [ "$KEYNAME" != "" ]; then
            su -c "cat $KEYNAME >> authorized_keys" $teaUser
        else
            redMessage "Error: could not find a key. You might need to create one manually at a later point."
        fi

    elif [ "$OPTION" == "Set password" ]; then
        passwd $teaUser
    fi
	
	if [ "$teaPath" == "" ]; then
		cd /home/$teaUser/
	else
		cd /$teaPath/$teaUser/
	fi
	
	cyanMessage " "
	cyanMessage "Getting TeaSpeak version..."
	greenOkAndSleep "# Newest version is ${TEASPEAK_VERSION}"

	cyanMessage " "
	greenOkAndSleep "# Downloading ${REQUEST_URL}"
	curl -s -S "$REQUEST_URL" -o teaspeak_latest.tar.gz
	greenOkAndSleep "# Unpacking and removing .tar.gz"
	tar -xzf teaspeak_latest.tar.gz
	rm teaspeak_latest.tar.gz
	greenOkAndSleep "DONE!"

	cyanMessage " "
	greenOkAndSleep "# Making scripts executable."
	if [ "$teaPath" == "" ]; then
		chown -R $teaUser:$teaUser /home/$teaUser/*
		chmod 774 /home/$teaUser/*.sh
	else
		chown -R $teaUser:$teaUser /$teaPath/$teaUser/*
		chmod 774 /$teaPath/$teaUser/*.sh
	fi
	greenOkAndSleep "DONE!"

	cyanMessage " "
	greenOkAndSleep "# Removing not needed packages."
	apt-get autoremove -y
	greenOkAndSleep "DONE!"

	cyanMessage " "
	greenOkAndSleep "Finished, TeaSpeak ${version} is now installed!"

fi

exit 0




