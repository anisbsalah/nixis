#! /usr/bin/env bash
set -e

setfont ter-v18b
clear

echo "
   ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
   ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
   ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
   ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
   ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
   ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"

echo
echo "######################################################################################################"
echo "################# User infos"
echo "######################################################################################################"
echo

set_password() {
	read -rs -p "[#?] Enter your '$1' password: " PASSWORD1
	echo
	read -rs -p "[#?] Confirm password: " PASSWORD2
	echo
	if [[ ${PASSWORD1} == "${PASSWORD2}" ]]; then
		smb_passwd="${PASSWORD1}"
	else
		echo "ERROR! Passwords do not match."
		set_password "$1"
	fi
}

echo "[#?] Enter your username:"
read -er username
echo
echo "[#?] Enter your Samba username:"
read -er smb_usr
echo
set_password "Samba"
echo
echo "[#?] Enter the IP address of your Samba server:"
read -er ip_address

echo
echo "######################################################################################################"
echo "################# Installing git..."
echo "######################################################################################################"
echo

nix-env -iA nixos.git

echo
echo "######################################################################################################"
echo "################# Partitioning the disk..."
echo "######################################################################################################"
echo

wipefs -a -f /dev/sda

parted --script /dev/sda mklabel msdos
parted --script /dev/sda mkpart primary ext4 1MiB 100%
parted --script /dev/sda set 1 boot on

partprobe /dev/sda

mkfs.ext4 -F -L nixos /dev/sda1

sleep 3

mount /dev/disk/by-label/nixos /mnt

echo
echo "######################################################################################################"
echo "################# Generating the initial nix configuration file..."
echo "######################################################################################################"
echo

nixos-generate-config --root /mnt

echo
echo "######################################################################################################"
echo "################# Cloning personal nix configuration..."
echo "######################################################################################################"
echo

git clone https://github.com/anisbsalah/nixos.git /tmp/nixos
find "/tmp/nixos/v2/system-modules/" -name "mount-cifs.nix" -exec sed -i "s|device = .*|device = \"//${ip_address}/SAMBASHARE\";|" {} \;
cp -r /tmp/nixos/v2/* /mnt/etc/nixos/

echo
echo "######################################################################################################"
echo "################# Installing NixOS..."
echo "######################################################################################################"
echo

nixos-install --no-root-passwd

echo
echo "######################################################################################################"
echo "################# Creating the samba credentials file..."
echo "######################################################################################################"
echo

echo "username=${smb_usr}" | tee "/mnt/home/${username}/.smb-secrets"
echo "password=${smb_passwd}" | tee -a "/mnt/home/${username}/.smb-secrets"
sudo chmod 600 "/mnt/home/${username}/.smb-secrets" # so that only the root user can read its contents

echo
echo "######################################################################################################"
echo "################# NixOS successfully installed."
echo "################# Rebooting now"
echo "######################################################################################################"
echo

sleep 1
reboot
