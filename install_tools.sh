#!/bin/bash

# Function to check if a command exists and install it if it doesn't
install_tool() {
    local tool=$1
    local install_cmd=$2
    local tool_path=$3

    if command -v "$tool" &> /dev/null; then
        echo -e "\e[32m$tool is already installed\e[0m"
    else
        echo -e "\e[33m$tool is not installed. Installing...\e[0m"
        eval "$install_cmd"
        if command -v "$tool" &> /dev/null || [[ -x "$tool_path" ]]; then
            echo -e "\e[32m$tool has been installed successfully\e[0m"
        else
            echo -e "\e[31mFailed to install $tool\e[0m"
        fi
    fi
}

remove_externally_managed() {
    # Loop through all Python directories in /usr/lib
    for py_dir in /usr/lib/python*; do
        # Check if it's a directory
        if [[ -d "$py_dir" ]]; then
            # Check if the EXTERNALLY-MANAGED file exists in that directory
            if [[ -f "$py_dir/EXTERNALLY-MANAGED" ]]; then
                # Remove the EXTERNALLY-MANAGED file with sudo
                sudo rm "$py_dir/EXTERNALLY-MANAGED"
                echo "Removed $py_dir/EXTERNALLY-MANAGED"
            fi
        fi
    done
}

# Call the function
remove_externally_managed

# Clear terminal nicely
clear

# Ensure yay is installed
if ! command -v yay &> /dev/null; then
    echo -e "\e[31m'yay' is not installed. Please install yay first.\e[0m"
    exit 1
fi

# Add the directory where wpscan is installed to PATH
export PATH=$PATH:$HOME/.local/share/gem/ruby/3.0.0/bin

# Install wpscan separately as it uses gem
install_tool "wpscan" "gem install wpscan" "$HOME/.local/share/gem/ruby/3.0.0/bin/wpscan"

# Define yay packages and install them
yay_packages=(
    lolcat
    nano
    brave
    rustscan
    neofetch
    inetutils
    seclists
    enum4linux
    metasploit
    sqlmap
    chisel
    ngrok
    exploit-db
    impacket
    htop
    tmux
    wireshark-qt
    tcpdump
    hashcat
    hydra
    socat
    p7zip
    amass
    autopsy
    dnsutils
    binwalk
    bloodhound
    burpsuite
    cewl
    cupp
    crunch
    code
    commix
    crowbar
    de4dot
    dex2jar
    dmitry
    dnschef
    dnsenum
    dos2unix
    dotdotpwn
    dumpzilla
    exiflooter
    exiv2
    eyewitness
    ffuf
    wfuzz
    fierce
    foremost
    ghidra
    gospider
    gparted
    guymager
    hakrawler
    hashdeep
    hashid
    iodine
    jadx
    john
    joomscan
    kerberoast
    linux-exploit-suggester
    lynis
    magicrescue
    maskprocessor
    mimikatz
    myrescue
    netcat
    nbtscan
    ripgrep
    nishang
    onesixtyone
    openssh
    openvpn
    ophcrack
    oscanner
    outguess
    padbuster
    patator
    payloadsallthethings
    pdf-parser
    pdfcrack
    peass-ng
    phpsploit
    pipal
    plocate
    portspoof
    powersploit
    pspy
    pwncat
    pyinstaller
    radare2
    rarcrack
    rdesktop
    recordmydesktop
    recoverjpeg
    responder
    rkhunter
    robotstxt
    ropper
    rz-ghidra
    s3scanner
    samba
    smbclient
    scapy
    scalpel
    sidguesser
    skipfish
    sleuthkit
    smbmap
    smtp-user-enum
    sn0int
    snmpcheck
    snmpenum
    sqlitebrowser
    sslscan
    stegcracker
    steghide
    subfinder
    subjack
    sucrack
    traceroute
    trufflehog
    unix-privesc-check
    whatweb
    whois
    windows-privesc-check
    wordlists
    xspy
    xsser
    yara
    chafa
)

# Loop through the yay packages and install each one if necessary
for package in "${yay_packages[@]}"; do
    if yay -Q "$package" &> /dev/null; then
        echo -e "\e[32m$package is already installed\e[0m"
    else
        echo -e "\e[33m$package is not installed. Installing...\e[0m"
        yay -S "$package" --noconfirm
        if yay -Q "$package" &> /dev/null; then
            echo -e "\e[32m$package has been installed successfully\e[0m"
        else
            echo -e "\e[31mFailed to install $package\e[0m"
        fi
    fi
done
