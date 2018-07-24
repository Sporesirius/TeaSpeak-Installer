#!/bin/bash

INSTALLER_VERSION="1.9"

# Colors.
function greenMessage() {
    echo -e "\\033[32;1m${@}\033[0m"
}

function cyanMessage() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function redMessage() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellowMessage() {
    echo -e "\\033[33;1m${@}\033[0m"
}

# Errors, warnings and info.
function errorExit() {
    redMessage ${@}
    exit 1
}

function okQuit() {
    redMessage "TeaSpeak Installer closed."
    exit 0
}

function invalidOption() {
    redMessage "Invalid option. Try another one."
}

function redWarnAnim() {
    redMessage $1
    sleep 1
}

function greenOkAnim() {
    greenMessage $1
    sleep 1
}

function yellowOkAnim() {
    yellowMessage $1
    sleep 1
}

cyanMessage " "
cyanMessage " "
redMessage "        TeaSpeak Installer"
cyanMessage " "
cyanMessage " "

# We need to be root to run the installer.
if [ "`id -u`" != "0" ]; then
    errorExit "Root account is required to run the install script!"
fi

# Check supported Linux distributions and package manager.
if cat /etc/*release | grep ^NAME | grep Debian &>/dev/null; then # Debian Distribution
    OS=Debian
    PM=apt
    PM2=dpkg
    greenOkAnim "${OS} detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=1
        pmID=1
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep Ubuntu &>/dev/null; then # Ubuntu Distribution
    OS=Ubuntu
    PM=apt
    PM2=dpkg
    greenOkAnim "Ubuntu detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=2
        pmID=1
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep openSUSE &>/dev/null; then # openSUSE Distribution
    OS=openSUSE
    PM=yzpper
    PM2=rpm
    greenOkAnim "openSUSE detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=3
        pmID=2
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep CentOS &>/dev/null; then # CentOS Distribution
    OS=CentOS
    PM=yum
    PM2=rpm
    greenOkAnim "CentOS detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=4
        pmID=3
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep Red &>/dev/null; then  # RedHat Distribution
    OS=RedHat
    PM=yum
    PM2=rpm
    greenOkAnim "RedHat detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=5
        pmID=3
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep Arch &>/dev/null; then # Arch Distribution
    OS=Arch
    PM=pacman
    greenOkAnim "Arch detected!"
    if { command -v ${PM}; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=6
        pmID=5
    else
        errorExit "${OS} detected, but the ${PM} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep Fedora &>/dev/null; then # Fedora Distribution
    OS=Fedora
    PM=dnf
    PM2=rpm
    greenOkAnim "Fedora detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=7
        pmID=4
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
elif cat /etc/*release | grep ^NAME | grep Mint &>/dev/null; then # Mint Distribution
    OS=Mint
    PM=apt
    PM2=dpkg
    greenOkAnim "Mint detected!"
    if { command -v ${PM} && command -v ${PM2} --help; } >/dev/null 2>&1; then
        yellowOkAnim "Using ${PM} package manager."
        osID=8
        pmID=1
    else
        errorExit "${OS} detected, but the ${PM} or ${PM2} package manager is missing!"
    fi
else
    errorExit "This Distribution is not supported!"
fi

# checkInstall for package manager.
function checkInstall {
    if [ "$pmID" == "1" ] && [ "`dpkg-query -s $1 2>/dev/null`" == "" ]; then # apt / dpkg
        greenOkAnim "Installing package $1"
        apt-get install -y $1
    elif [ "$pmID" == "2" ] && [ "`rpm -qa | grep ^$1 2>/dev/null`" == "" ]; then # yzpper / rpm
        greenOkAnim "Installing package $1"
        zypper install -y $1
    elif [ "$pmID" == "3" ] && [ "`rpm -qa | grep ^$1 2>/dev/null`" == "" ]; then # yum / rpm
        greenOkAnim "Installing package $1"
        yum install -y $1
    elif [ "$pmID" == "4" ] && [ "`rpm -qa | grep ^$1 2>/dev/null`" == "" ]; then # dnf / rpm
        greenOkAnim "Installing package $1"
        dnf install -y $1
    elif [ "$pmID" == "5" ] && [ "`pacman -Qi $1 2>/dev/null`" == "" ]; then # pacman
        greenOkAnim "Installing package $1"
        pacman -S --noconfirm $1
    else
        yellowMessage "Package $1 already installed. Skip!"
    fi
}

# Check packages for the installer.
if ! { command -v curl && command -v wget && command -v tar; } >/dev/null 2>&1; then
    cyanMessage " "
    redMessage "WARNING: One of curl, wget or tar is not installed!"
    cyanMessage "Install needed packages?"
    cyanMessage "*The installer needs wget, curl and tar to run."
    OPTIONS=("Yes" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1 ) break;;
            2 ) okQuit;;
            *) invalidOption;continue;;
        esac
    done
	
    if [ "$OPTION" == "Yes" ]; then
        cyanMessage " "
        greenOkAnim "# Installing necessary TeaSpeak-Installer packages..."
        checkInstall wget
        checkInstall curl
        checkInstall tar
        greenOkAnim "DONE!"
    fi
fi

# Repositories check over https.
cyanMessage " "
cyanMessage "Checking if the repositories are online and healthy..."

teaspeakRepoName="TeaSpeak"
teaspeakURLCheck=https://repo.teaspeak.de

githubRepoName="Github"
githubURLCheck=https://github.com

centosRepoName="CentOS: NUX Desktop"
centosURLCheck=https://li.nux.ro/download

fedoraRepoName="Fedora: RPM Fusion"
fedoraURLCheck=https://download1.rpmfusion.org

getTeaspeakStatus=$(curl -s --connect-timeout 3 -LI ${teaspeakURLCheck} -o /dev/null -w %{http_code} 2>&1)
getGithubStatus=$(curl -s --connect-timeout 3 -LI ${githubURLCheck} -o /dev/null -w %{http_code} 2>&1)
if [ "$osID" == "4" ]; then
    getCentosStatus=$(curl -s --connect-timeout 3 -LI ${centosURLCheck} -o /dev/null -w %{http_code} 2>&1)
    check_repo=( "$getTeaspeakStatus" "$getGithubStatus" "$getCentosStatus")
    check_repo2=( "$teaspeakRepoName" "$githubRepoName" "$centosRepoName")
elif [ "$osID" == "7" ]; then
    getFedoraStatus=$(curl -s --connect-timeout 3 -LI ${fedoraURLCheck} -o /dev/null -w %{http_code} 2>&1)
    check_repo=( "$getTeaspeakStatus" "$getGithubStatus" "$getFedoraStatus" )
    check_repo2=( "$teaspeakRepoName" "$githubRepoName" "$fedoraRepoName" )
else
    check_repo=( "$getTeaspeakStatus" "$getGithubStatus" )
    check_repo2=( "$teaspeakRepoName" "$githubRepoName" )
fi

for ((i=0;i<${#check_repo[@]};++i)); do
    if [ "${check_repo[i]}" == "200" ]; then
        greenMessage ""${check_repo2[i]}" Repository is healthy. All is good!"
    else
        redMessage ""${check_repo2[i]}" Repository seems to be unavailable!"
        if [ "${check_repo[i]}" == "000" ]; then
            errorExit "URL cannot be found, maybe this URL does not exist?"
        else
            errorExit "HTTP status code: "${check_repo[i]}""
        fi
    fi
done

# Unlock links if check was successful.
# TeaSpeak Repository
if [ "$getTeaspeakStatus" == "200" ]; then
    TEASPEAK_VERSION=$(curl -s --connect-timeout 60 -S -k https://repo.teaspeak.de/latest)
    REQUEST_URL="https://repo.teaspeak.de/server/linux/x64/TeaSpeak-${TEASPEAK_VERSION}.tar.gz"
fi

# Github Repository.
if [ "$getGithubStatus" == "200" ]; then
    INSTALLER_REPO_URL="https://api.github.com/repos/Sporesirius/TeaSpeak-Installer/releases/latest"
    LATEST_VERSION=`wget -q --timeout=60 -O - ${INSTALLER_REPO_URL} | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)'`
    GET_NEW_VERSION="https://github.com/Sporesirius/TeaSpeak-Installer/archive/${LATEST_VERSION}.tar.gz"
fi

# CentOS: NUX Desktop Repository.
if [ "$osID" == "4" ]; then
    if [ "$getCentosStatus" == "200" ]; then
        CENTOS_REPO="https://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm"
    fi
fi

# Fedora: RPM Fusion Repository.
if [ "$osID" == "7" ]; then
    if [ "$getFedoraStatus" == "200" ]; then
        FEDORA_REPO="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-24.noarch.rpm"
    fi
fi
greenOkAnim "DONE!"

# Auto updater
cyanMessage " "
cyanMessage "Checking for the latest installer version..."
if [ "`printf "${LATEST_VERSION}\n${INSTALLER_VERSION}" | sort -V | tail -n 1`" != "$INSTALLER_VERSION" ]; then
    redMessage "New version ${LATEST_VERSION} available!"
    yellowMessage "You are using the version ${INSTALLER_VERSION}."
    cyanMessage " "
    cyanMessage "Do you want to update the installer script?"
    OPTIONS=("Download" "Skip" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            3 ) okQuit;;
            *) invalidOption;continue;;
        esac
    done

    if [ "$OPTION" == "Download" ]; then
        cyanMessage " "
        greenOkAnim "# Downloading new installer version..."
        wget --timeout=60 ${GET_NEW_VERSION} -O installer_latest.tar.gz
        greenOkAnim "DONE!"

        cyanMessage " "
        greenOkAnim "# Unpacking installer and replace the old installer with the new one."
        tar -xzf installer_latest.tar.gz
        rm installer_latest.tar.gz
        cd TeaSpeak-Installer-*
        cp teaspeak_install.sh ../teaspeak_install.sh
        cd ..
        rm -R TeaSpeak-Installer-*
        greenOkAnim "DONE!"

        cyanMessage " "
        greenOkAnim "# Making new script executable."
        chmod 774 teaspeak_install.sh
        greenOkAnim "DONE!"

        cyanMessage " "
        greenOkAnim "# Restarting script now"
        clear
        ./teaspeak_install.sh
        exit 0
    elif [ "$OPTION" == "Skip" ]; then
        yellowOkAnim "New installer version skiped."
    fi
else
    greenOkAnim "# You are using the up to date version ${INSTALLER_VERSION}."
fi

# Update system and install TeaSpeak packages.
cyanMessage " "
cyanMessage "Update the system packages to the latest version?"
cyanMessage "*It is recommended to update the system, otherwise dependencies might brake!"
OPTIONS=("Update" "Skip" "Quit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        3 ) okQuit;;
        *) invalidOption;continue;;
    esac
done
	
if [ "$OPTION" == "Update" ]; then
    greenOkAnim "# Updating the system packages..."
    if [ "$pmID" == "1" ]; then # apt / dpkg
        apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
    elif [ "$pmID" == "2" ]; then # yzpper / rpm
        zypper ref && zypper up
    elif [ "$pmID" == "3" ]; then # yum / rpm
        yum update -y
    elif [ "$pmID" == "4" ]; then # dnf / rpm
        dnf check-update -y && dnf upgrade -y
    elif [ "$pmID" == "5" ]; then # pacman
        pacman -Syu --noconfirm
    fi
    greenOkAnim "DONE!"
elif [ "$OPTION" == "Skip" ]; then
    yellowOkAnim "System update skiped."
fi
    
cyanMessage " "
greenOkAnim "# Installing necessary TeaSpeak packages..."
checkInstall screen
if [ "$osID" == "4" ] || [ "$osID" == "7" ]; then
    cyanMessage " "
    yellowOkAnim "NOTE: This distribution (${OS}) requires additional repositories to install ffmpeg!"
    cyanMessage "Do you want to add the extra repository and install ffmpeg?"
    cyanMessage "*Required if you want to use the musicbot."
    OPTIONS=("Install" "Skip" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2 ) break;;
            3 ) okQuit;;
            *) invalidOption;continue;;
        esac
    done
	
    if [ "$OPTION" == "Install" ]; then
        if [ "$osID" == "4" ]; then
            checkInstall ${CENTOS_REPO}
            checkInstall ffmpeg
        elif [ "$osID" == "7" ]; then
            checkInstall ${FEDORA_REPO}
            checkInstall ffmpeg
        fi
    elif [ "$OPTION" == "Skip" ]; then
        yellowOkAnim "Additional repositories and package ffmpeg skiped."
    fi
else
    checkInstall ffmpeg
fi
if [ "$osID" == "4" ] || [ "$osID" == "5" ] || [ "$osID" == "6" ] || [ "$osID" == "7" ]; then
    cyanMessage " "
    redWarnAnim "WARNING: This distribution (${OS}) has no libav-tools in its repositories, please compile it yourself."
    redMessage "*The web client cannot be used without libav-tools!"
else
    checkInstall libav-tools
fi
# Install youtube-dl.
cyanMessage " "
cyanMessage "Do you want to install youtube-dl?"
cyanMessage "*Required if you want to use the musicbot with youtube."
OPTIONS=("Install" "Skip" "Quit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        3 ) okQuit;;
        *) invalidOption;continue;;
    esac
done
	
if [ "$OPTION" == "Install" ]; then
    checkInstall youtube-dl
elif [ "$OPTION" == "Skip" ]; then
    yellowOkAnim "Package youtube-dl skiped."
fi
greenOkAnim "DONE!"
	
# Create user, yes or no?
cyanMessage " "
cyanMessage "Do you want to create a TeaSpeak user?"
cyanMessage "*It is recommended to create a separated TeaSpeak user!"
OPTIONS=("Yes" "No" "Quit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        3 ) okQuit;;
        *) invalidOption;continue;;
    esac
done
	
if [ "$OPTION" == "Yes" ]; then
    cyanMessage " "
    cyanMessage "Please enter the name of the TeaSpeak user."
    read teaUser
    noUser=false
elif [ "$OPTION" == "No" ]; then
    yellowOkAnim "User creation skiped."
    noUser=true
fi
	
# TeaSpeak install path.
cyanMessage " "
cyanMessage "Please enter the TeaSpeak installation path."
cyanMessage "Empty input = /home/ | Example input = /srv/"
read teaPath
if [[ -z "$teaPath" ]]; then
    teaPath='home'
fi
	
# Key, password or disabled login.
if [ "$noUser" == "false" ]; then
    cyanMessage " "
    cyanMessage "Create key, set password or set no login?"

    OPTIONS=("Create key" "Set password" "No Login" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2|3 ) break;;
            4 ) okQuit;;
            *) invalidOption;continue;;
        esac
    done

    if [ "$OPTION" == "Create key" ]; then
       if { command -v ssh-keygen; } >/dev/null 2>&1; then
            groupadd $teaUser
            mkdir -p /$teaPath
            useradd -m -b /$teaPath -s /bin/bash -g $teaUser $teaUser

            if [ -d /$teaPath/$teaUser/.ssh ]; then
                rm -rf /$teaPath/$teaUser/.ssh
            fi

            mkdir -p /$teaPath/$teaUser/.ssh
            chown $teaUser:$teaUser /$teaPath/$teaUser/.ssh
            cd /$teaPath/$teaUser/.ssh

            cyanMessage " "
            cyanMessage "It is recommended, but not required to set a password."
            su -c "ssh-keygen -t rsa" $teaUser

            KEYNAME=`find -maxdepth 1 -name "*.pub" | head -n 1`

            if [ "$KEYNAME" != "" ]; then
                su -c "cat $KEYNAME >> authorized_keys" $teaUser
            else
                redMessage "Could not find a key. You might need to create one manually at a later point."
            fi
        else
            errorExit "Can't find ssh-keygen to create a key!"
        fi
    elif [ "$OPTION" == "Set password" ]; then
        groupadd $teaUser
        mkdir -p /$teaPath
        useradd -m -b /$teaPath -s /bin/bash -g $teaUser $teaUser

        passwd $teaUser
    elif [ "$OPTION" == "No Login" ]; then
        groupadd $teaUser
        mkdir -p /$teaPath
        useradd -m -b /$teaPath -s /usr/sbin/nologin -g $teaUser $teaUser
    fi
fi
	
if [ "$noUser" == "false" ]; then
    cd /$teaPath/$teaUser/
else
    mkdir -p /$teaPath
    cd /$teaPath/
fi
	
# Downloading and setting up TeaSpeak.
cyanMessage " "
cyanMessage "Getting TeaSpeak version..."
greenOkAnim "# Newest version is ${TEASPEAK_VERSION}"

cyanMessage " "
greenOkAnim "# Downloading ${REQUEST_URL}"
curl --connect-timeout 60 -s -S "$REQUEST_URL" -o teaspeak_latest.tar.gz
greenOkAnim "# Unpacking and removing .tar.gz"
tar -xzf teaspeak_latest.tar.gz
rm teaspeak_latest.tar.gz
greenOkAnim "DONE!"

cyanMessage " "
greenOkAnim "# Making scripts executable."
if [ "$noUser" == "false" ]; then
    chown -R $teaUser:$teaUser /$teaPath/$teaUser/*
    chmod 774 /$teaPath/$teaUser/*.sh
else
    chown -R root:root /$teaPath/*
    chmod 774 /$teaPath/*.sh
fi
greenOkAnim "DONE!"

cyanMessage " "
greenOkAnim "Finished, TeaSpeak ${TEASPEAK_VERSION} is now installed!"

exit 0




