#!/bin/bash
# TeaSpeak Installer
# by Sporesirius and WolverinDEV

INSTALLER_VERSION="1.12"

function debug() {
    #echo "debug > ${@}"
    :
}

function warn() {
    echo -e "\\033[33;1m${@}\033[0m"
}

function error() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function info() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function green() {
    echo -e "\\033[32;1m${@}\033[0m"
}

function cyan() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function red() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellow() {
    echo -e "\\033[33;1m${@}\033[0m"
}

function option_quit_installer() {
    red "TeaSpeak Installer closed."
    exit 0
}

function invalid_option() {
    red "Invalid option. Try another one."
}

function red_sleep() {
    red $1
    sleep 1
}

function green_sleep() {
    green $1
    sleep 1
}

function yellow_sleep() {
    yellow $1
    sleep 1
}

# Check if sudo is installed.
if sudo -v >/dev/null 2>&1; then
    SUDO_PREFIX="sudo"
    debug "Sudo installed"
elif [ "`id -u`" != "0" ]; then
    error "Root or sudo privileges are required to run the install script!"
    exit 1
fi

# Detect architecture.
MACHINE_TYPE=`${SUDO_PREFIX} uname -m`
if [ ${MACHINE_TYPE} == "x86_64" ]; then
    ARCH="amd64"
else
    ARCH="x86"
fi

function detect_packet_manager() {
    PACKET_MANAGER_NAME=""
    PACKET_MANAGER_TEST=""
    PACKET_MANAGER_UPDATE=""
    PACKET_MANAGER_INSTALL=""

    SUPPORT_SCREEN=false
    SUPPORT_FFMPEG=false
    SUPPORT_YTDL=false
    SUPPORT_LIBNICE=false

    NEDDED_REPO=false
	
    CentOS_REPO="https://negativo17.org/repos/epel-multimedia.repo"
    CentOS_6_REPO="${CentOS_REPO}"
    CentOS_7_REPO="${CentOS_REPO}"
    RedHat_REPO="${CentOS_REPO}"
    Fedora_REPO="https://negativo17.org/repos/fedora-multimedia.repo"

    #<system name>| <packages>| <manager>| <repos>| <system version> (command seperated by :)
    PACKET_MANAGERS=(
        "Debian|screen:ffmpeg:youtube-dl:libnice10|apt:dpkg-query||"
        "Ubuntu|screen:ffmpeg:youtube-dl:libnice10|apt:dpkg-query||"
        "openSUSE|screen:ffmpeg:youtube-dl:libnice10|yzpper:rpm||"
        "CentOS|screen:ffmpeg:youtube-dl:libnice:yum-utils|yum:rpm|${CentOS_6_REPO}|6"
        "CentOS|screen:ffmpeg:youtube-dl:libnice:yum-utils|yum:rpm|${CentOS_7_REPO}|7"
        "RedHat|screen:ffmpeg:youtube-dl:libnice:yum-utils|yum:rpm|${RedHat_REPO}|"
        "Arch|screen:ffmpeg:youtube-dl:libnice|pacman||"
        "Fedora|screen:ffmpeg:youtube-dl:libnice|dnf:rpm|${Fedora_REPO}|"
        "Mint|screen:ffmpeg:youtube-dl:libnice10|apt:dpkg-query||"
    )
    PACKET_MANAGER_COMMANDS=(
        "apt:dpkg-query|dpkg-query -s %s|apt update -y && ${SUDO_PREFIX} apt upgrade -y|apt install -y %s"
        "yzpper:rpm|rpm -q %s|zypper ref && ${SUDO_PREFIX} zypper up|zypper install -y %s"
        "yum:rpm|rpm -q %s|yum update -y|yum install -y %s"
        "pacman|pacman -Qi %s|pacman -Syu --noconfirm|pacman -S --noconfirm %s"
        "dnf:rpm|rpm -q %s|dnf check-update -y && ${SUDO_PREFIX} dnf upgrade -y|dnf install -y %s"
    )
    SYSTEM_NAME=$(cat /etc/*release | grep ^NAME)
    SYSTEM_VERSION=$(cat /etc/*release | grep ^VERSION_ID | sed 's/[^0-9]*//g')
    SYSTEM_NAME_DETECTED="" #Give the system out own name :D

    for system in ${PACKET_MANAGERS[@]}
    do
        IFS='|' read -r -a data <<< $system
        debug "Testing ${system} => ${data[0]}"

        if echo "${SYSTEM_NAME}" | grep "${data[0]}" &>/dev/null && echo "${SYSTEM_VERSION}" | grep "${data[4]}" &>/dev/null; then
            SYSTEM_NAME_DETECTED="${data[0]}"
            SYSTEM_VERSION="${data[4]}"
            if [ "${data[4]}" == "" ]; then
            SYSTEM_VERSION=$(cat /etc/*release | grep ^VERSION_ID | sed 's/[^0-9]*//g')
            fi
        else
            continue
        fi

        cyan " "
        green "${SYSTEM_NAME_DETECTED} ${SYSTEM_VERSION} (${ARCH}) detected!"
        debug "Found system ${data[0]} ${SYSTEM_VERSION} (${ARCH})"
        for index in $(seq 2 ${#data[@]})
        do
            PACKET_MANAGER_NAME=${data[${index}]}

            debug "Testing commands ${PACKET_MANAGER_NAME}"
            for command in ${PACKET_MANAGER_NAME//:/ }
            do
                debug "Testing command ${command}"
                if ! [ $(command -v ${command}) >/dev/null 2>&1 ]; then
                    PACKET_MANAGER_NAME=""
                    break
                fi
            done
            if [ ${PACKET_MANAGER_NAME} != "" ]; then
                break
            fi
        done

        if ! [ "${PACKET_MANAGER_NAME}" == "" ]; then
            # Supported packages.
            echo "${data[1]}" | grep "screen" />/dev/null 2>&1
            if [ $? -ne 0 ]; then
                SUPPORT_SCREEN=true
            fi
			
            echo "${data[1]}" | grep "ffmpeg" />/dev/null 2>&1
            if [ $? -ne 0 ]; then
                SUPPORT_FFMPEG=true
            fi
			
            echo "${data[1]}" | grep "youtube-dl" />/dev/null 2>&1
            if [ $? -ne 0 ]; then
                SUPPORT_YTDL=true
            fi
			
            echo "${data[1]}" | grep "(libnice|libnice10)" />/dev/null 2>&1
            if [ $? -ne 0 ]; then
                SUPPORT_LIBNICE=true
            fi

            # Additional repository enabled.
            if [ "${data[3]}" != "" ]; then
                debug "Additional repo needed"
                NEDDED_REPO=true
            fi
            break
        fi
    done

    if [ "${PACKET_MANAGER_NAME}" == "" ]; then
        error "Failed to determine your system and the packet manager on it! (System: ${SYSTEM_NAME_DETECTED} ${SYSTEM_VERSION} ${ARCH})"
        return 1
    fi

    IFS='~'
    for manager_commands in ${PACKET_MANAGER_COMMANDS[@]}
    do
        IFS='|' read -r -a commands <<< $manager_commands

        if [ "${commands[0]}" == "${PACKET_MANAGER_NAME}" ]; then
            PACKET_MANAGER_INSTALL="${commands[3]}"
            PACKET_MANAGER_UPDATE="${commands[2]}"
            PACKET_MANAGER_TEST="${commands[1]}"
            break
        fi
    done

    if [ "${PACKET_MANAGER_INSTALL}" == "" ]; then
        error "Failed to find packet manager commands for manager (${PACKET_MANAGER_NAME})"
        return 1
    fi

    info "Got packet manager commands:"
    info "Install                    : ${PACKET_MANAGER_INSTALL}"
    info "Update                     : ${PACKET_MANAGER_UPDATE}"
    info "Test                       : ${PACKET_MANAGER_TEST}"
    info "Packet screen support      : ${SUPPORT_SCREEN}"
    info "Packet ffmpeg support      : ${SUPPORT_FFMPEG}"
    info "Packet youtube-dl support  : ${SUPPORT_YTDL}"
    info "Packet libnice support     : ${SUPPORT_LIBNICE}"
    info "Additional repository      : ${NEDDED_REPO}"
    debug "${data[3]}"
    return 0
}

function test_installed() {
    local require_install=()

    for package in "${@}"
    do
        local command=$(printf ${PACKET_MANAGER_TEST} "${package}")
        debug ${command}
        eval "${command}" &>/dev/null
        if [ $? -ne 0 ]; then
            cyan " "
            warn "${package} is required, but missing!"
            require_install+=(${package})
        fi
    done

    if [ ${#require_install[@]} -lt 1 ]; then
        echo ${#require_install[@]} &>/dev/null
        return 0
    fi

    packages=$(printf " %s" "${require_install[@]}")
    packages=${packages:1}

    packages_human=$(printf ", \"%s\"" "${require_install[@]}")
    packages_human=${packages_human:2}

    cyan "Should we install "${packages_human}" for you? (Required root or administrator privileges)"
    OPTIONS=("Yes" "No" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2) break;;
            3 ) option_quit_installer;;
            *)  invalid_option; continue;;
        esac
    done

    if [ "$OPTION" == "${OPTIONS[0]}" ]; then
        green_sleep "# Installing "${packages_human}" package..."
        local command=$(printf ${PACKET_MANAGER_INSTALL} "${packages}")
        debug ${SUDO_PREFIX} ${command}
        eval "${SUDO_PREFIX} ${command}"
        green_sleep "DONE!"
        if [ $? -ne 0 ]; then
            error "Failed to install required package!"
            exit 1
        fi
        return 0
    fi
    return 2
}

function updateScript() {
    INSTALLER_REPO_URL="https://api.github.com/repos/Sporesirius/TeaSpeak-Installer/releases/latest"
    INSTALLER_REPO_PACKAGE="https://github.com/Sporesirius/TeaSpeak-Installer/archive/%s.tar.gz"

    cyan " "
    cyan "Checking for the latest installer version..."
    LATEST_VERSION=$(curl -s --connect-timeout 10 -S -L ${INSTALLER_REPO_URL} | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]+)')
    if [ $? -ne 0 ]; then
        warn "Failed to check for updates for this script!"
        return 1
    fi

    if [ "`printf "${LATEST_VERSION}\n${INSTALLER_VERSION}" | sort -V | tail -n 1`" != "$INSTALLER_VERSION" ]; then
        red "New version ${LATEST_VERSION} available!"
        yellow "You are using the version ${INSTALLER_VERSION}."
        cyan " "
        cyan "Do you want to update the installer script?"
        OPTIONS=("Download" "Skip" "Quit")
        select OPTION in "${OPTIONS[@]}"; do
            case "$REPLY" in
                1|2 ) break;;
                3 ) option_quit_installer;;
                *)  invalid_option; continue;;
            esac
        done

        if [ "$OPTION" == "${OPTIONS[0]}" ]; then
            cyan " "
            green_sleep "# Downloading new installer version..."
            ${SUDO_PREFIX} curl -s --connect-timeout 10 -S -L `printf ${INSTALLER_REPO_PACKAGE} "${LATEST_VERSION}"` -o installer_latest.tar.gz
            if [ $? -ne 0 ]; then
                warn "Failed to download update. Update failed!"
                return 1
            fi
            green_sleep "Done!"

            cyan " "
            green_sleep "# Unpacking installer and replace the old installer with the new one."
            ${SUDO_PREFIX} tar -xzf installer_latest.tar.gz
            ${SUDO_PREFIX} rm installer_latest.tar.gz
            ${SUDO_PREFIX} cp TeaSpeak-Installer-*/teaspeak_install.sh teaspeak_install.sh
            ${SUDO_PREFIX} rm -r TeaSpeak-Installer-*
            green_sleep "Done!"

            cyan " "
            green_sleep "# Adjusting script rights for execution."
            ${SUDO_PREFIX} chmod 774 teaspeak_install.sh
            green_sleep "Done!"

            cyan " "
            green_sleep "# Restarting update script!"
            sleep 1
            clear
            ${SUDO_PREFIX} ./teaspeak_install.sh
            exit 0
        fi
        if [ $? -ne 0 ]; then
            yellow_sleep "New installer version skiped."
        fi
    else
        green_sleep "# You are using the up to date version ${INSTALLER_VERSION}."
    fi
}

function secure_user() {
    cyan " "
    cyan "Create key, set password or set no login?"

    OPTIONS=("Create key" "Set password" "No Login" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2|3 ) break;;
            4 ) option_quit_installer;;
            *) invalid_option;continue;;
        esac
    done

    if [ "$OPTION" == "${OPTIONS[0]}" ]; then
        if { command -v ssh-keygen; } >/dev/null 2>&1; then
            ${SUDO_PREFIX} groupadd $teaUser
            ${SUDO_PREFIX} mkdir -p /$teaPath
            ${SUDO_PREFIX} useradd -m -b /$teaPath -s /bin/bash -g $teaUser $teaUser
            if [ $? -ne 0 ]; then
                error "Failed to create the TeaSpeak user!"
                exit 1
            fi

            if [ -d /$TEASPEAK_DIR/.ssh ]; then
                ${SUDO_PREFIX} rm -rf /$TEASPEAK_DIR/.ssh
            fi

            ${SUDO_PREFIX} mkdir -p /$TEASPEAK_DIR/.ssh
            ${SUDO_PREFIX} chown $teaUser:$teaUser /$TEASPEAK_DIR/.ssh
            cd /$TEASPEAK_DIR/.ssh

            cyan " "
            cyan "It is recommended, but not required to set a password."
            ${SUDO_PREFIX} su -c "ssh-keygen -t rsa" $teaUser
            if [ $? -ne 0 ]; then
                error "Failed to create a SSH Key!"
                exit 1
            fi

            KEYNAME=`find -maxdepth 1 -name "*.pub" | head -n 1`

            if [ "$KEYNAME" != "" ]; then
                ${SUDO_PREFIX} su -c "cat $KEYNAME >> authorized_keys" $teaUser
                if [ $? -ne 0 ]; then
                    error "Could not find a key!"
                    exit 1
                fi
            fi
        fi
    elif [ "$OPTION" == "${OPTIONS[1]}" ]; then
        ${SUDO_PREFIX} groupadd $teaUser
        ${SUDO_PREFIX} mkdir -p /$teaPath
        ${SUDO_PREFIX} useradd -m -b /$teaPath -s /bin/bash -g $teaUser $teaUser
        if [ $? -ne 0 ]; then
            error "Failed to create the TeaSpeak user! Maybe wrong password or existing user?"
            exit 1
        fi
        ${SUDO_PREFIX} passwd $teaUser
    elif [ "$OPTION" == "${OPTIONS[2]}" ]; then
        ${SUDO_PREFIX} groupadd $teaUser
        ${SUDO_PREFIX} mkdir -p /$teaPath
        ${SUDO_PREFIX} useradd -m -b /$teaPath -s /usr/sbin/nologin -g $teaUser $teaUser
        if [ $? -ne 0 ]; then
            error "Failed to create the TeaSpeak user!"
            exit 1
        fi
    fi
}

cyan " "
cyan " "
red "        TeaSpeak Installer"
cyan "       by Sporesirius and WolverinDEV"
cyan " "

yellow "NOTE: You can exit the script any time with CTRL+C"
yellow "      but not at every point recommendable!"

# Get packet manager commands.
detect_packet_manager
if [ $? -ne 0 ]; then
    error "Exiting installer"
    unset IFS;
    exit 1
fi

# Update system packages.
cyan " "
cyan "Update the package list to the latest version?"
warn "WARN: It is recommended to update the system before run the installer, otherwise dependencies might brake or the script may not work properly!"
OPTIONS=("Update" "Skip (Not recommended)" "Quit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        3 ) option_quit_installer;;
        *) invalid_option;continue;;
    esac
done

if [ "$OPTION" == "${OPTIONS[0]}" ]; then
    green_sleep "# Updating the system packages..."
    eval "${SUDO_PREFIX} ${PACKET_MANAGER_UPDATE}"
    green_sleep "DONE!"
elif [ "$OPTION" == "Skip" ]; then
    yellow_sleep "System update skiped."
fi

# Install packages for the installer itself.
test_installed curl
test_installed tar
if [ $? -ne 0 ]; then
    error "Failed to install required packages for the installer!"
    exit 1
fi

# Update installer script.
updateScript
if [ $? -ne 0 ]; then
    error "Failed to update script!"
    exit 1
fi

# Check if repo is needed.
if [ "${NEDDED_REPO}" == "true" ] && ! yum -v repolist all 2>/dev/null | grep "epel-multimedia" &>/dev/null && ! dnf -v repolist all | grep "fedora-multimedia" &>/dev/null; then
    cyan " "
    warn "NOTE: This distribution (${SYSTEM_NAME_DETECTED} ${SYSTEM_VERSION} ${ARCH}) requires the "${data[3]}" repository to install ffmpeg!"
    cyan "Should we add "${data[3]}" to your repository list? (Required root or administrator privileges)"
    OPTIONS=("Yes" "No" "Quit")
    select OPTION in "${OPTIONS[@]}"; do
        case "$REPLY" in
            1|2) break;;
            3 ) option_quit_installer;;
            *)  invalid_option; continue;;
        esac
    done

    if [ "$OPTION" == "${OPTIONS[0]}" ]; then
        green_sleep "# Adding "${data[3]}" repository..."
        for i in ${data[3]};
        do
            if [ "$SYSTEM_NAME_DETECTED" == "(CentOS|RedHat)" ]; then
                yum-config-manager --add-repo $i
			elif [ "$SYSTEM_NAME_DETECTED" == "Fedora" ]; then
                dnf config-manager --add-repo $i
            fi
            if [ $? -ne 0 ]; then
                error "Failed to add required repository for your distribution (${SYSTEM_NAME_DETECTED} ${SYSTEM_VERSION})!"
                exit 1
            fi
        done
    fi
fi

# Begin install needed TeaSpeak packages.
beginIFS=$endIFS
IFS=":"
split_data=${data[1]}
endIFS=$beginIFS
for split_package in ${split_data[@]}
do
    test_installed ${split_package}
    if [ $? -ne 0 ]; then
        error "Failed to install required packages for TeaSpeak!"
        exit 1
    fi
done
unset IFS;

# Create user, yes or no?
cyan " "
cyan "Do you want to create a TeaSpeak user?"
cyan "*It is recommended to create a separated TeaSpeak user!"
OPTIONS=("Yes" "No" "Quit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        3 ) option_quit_installer;;
        *) invalid_option;continue;;
    esac
done

if [ "$OPTION" == ${OPTIONS[0]} ]; then
    cyan " "
    cyan "Please enter the name of the TeaSpeak user."
    read teaUser
    NO_USER=false
elif [ "$OPTION" == ${OPTIONS[1]} ]; then
    NO_USER=true
    yellow_sleep "User creation skiped."
fi

# TeaSpeak install path.
cyan " "
cyan "Please enter the TeaSpeak installation path."
cyan "Empty input = /home/ | Example input = /srv/"
read teaPath
if [ -z "$teaPath" ]; then
    teaPath='home'
fi

TEASPEAK_DIR="/${teaPath}/${teaUser}"

if [ "$NO_USER" == "false" ]; then
    secure_user
    if [ $? -ne 0 ]; then
        error "Failed to set security option!"
        exit 1
    fi
fi

${SUDO_PREFIX} mkdir -p $TEASPEAK_DIR
cd $TEASPEAK_DIR
	
# Downloading and setting up TeaSpeak.
cyan " "
cyan "Getting TeaSpeak version..."
TEASPEAK_VERSION=$(curl -s --connect-timeout 10 -S -L -k https://repo.teaspeak.de/server/linux/${ARCH}/latest)
TEA_REQUEST_URL="https://repo.teaspeak.de/server/linux/${ARCH}/TeaSpeak-${TEASPEAK_VERSION}.tar.gz"
if [ $? -ne 0 ]; then
    error "Failed to load the latest TeaSpeak version!"
    exit 1
fi
green_sleep "# Newest version is ${TEASPEAK_VERSION}"

cyan " "
green_sleep "# Downloading ${TEA_REQUEST_URL} to ${TEASPEAK_DIR}"
${SUDO_PREFIX} curl -s --connect-timeout 10 -S -L "$TEA_REQUEST_URL" -o teaspeak_latest.tar.gz
if [ $? -ne 0 ]; then
    error "Failed to download the latest TeaSpeak version!"
    exit 1
fi
sleep 1
green_sleep "# Unpacking and removing .tar.gz"
${SUDO_PREFIX} tar -xzf teaspeak_latest.tar.gz
${SUDO_PREFIX} rm teaspeak_latest.tar.gz
green_sleep "DONE!"

cyan " "
green_sleep "# Making scripts executable."
${SUDO_PREFIX} chown -R $teaUser:$teaUser /$teaPath/$teaUser/*
${SUDO_PREFIX} chmod 774 /$TEASPEAK_DIR/*.sh
green_sleep "DONE!"

cyan " "
green_sleep "Finished, TeaSpeak ${TEASPEAK_VERSION} is now installed!"

# Start TeaSpeak in minimal mode.
cyan " "
cyan "Do you want to start TeaSpeak?"
cyan "*Please save the Serverquery login and the Serveradmin token the first time you start TeaSpeak!"
cyan "*CTRL+C = Exit"
OPTIONS=("Start server" "Finish and exit")
select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
        1|2 ) break;;
        *) invalid_option;continue;;
    esac
done
	
if [ "$OPTION" == "${OPTIONS[0]}" ]; then
    cyan " "
    green_sleep "# Starting TeaSpeak..."
    cd $TEASPEAK_DIR; ${SUDO_PREFIX} LD_LIBRARY_PATH="$LD_LIBRARY_PATH;./libs/" ./TeaSpeakServer; stty cooked echo
	
    cyan " "
    green_sleep "# Making new created files executable."
    ${SUDO_PREFIX} chown -R $teaUser:$teaUser /$TEASPEAK_DIR/*
    ${SUDO_PREFIX} chmod 774 /$TEASPEAK_DIR/*.sh
    green_sleep "DONE!"
fi

cyan " "
yellow "NOTE: It is recommended to start the TeaSpeak server with the created user!"
yellow "      to start the TeaSpeak you can use the following bash scripts:"
yellow "      teastart.sh, teastart_minimal.sh, teastart_autorestart.sh and tealoop.sh."
green_sleep "Script successfully completed."

exit 0
