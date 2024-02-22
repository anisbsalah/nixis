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
	read -r -sp "[#?] Enter your '$1' password: " PASSWORD1
	echo
	read -r -sp "[#?] Confirm password: " PASSWORD2
	echo
	if [[ ${PASSWORD1} == "${PASSWORD2}" ]]; then
		declare -n VARIABLE="$2"
		VARIABLE="${PASSWORD1}"
	else
		printf "ERROR! Passwords do not match. Try again.\n\n"
		set_password "$1" "$2"
	fi
}

echo "[#?] Enter your username:"
read -er username
echo
echo "[#?] Enter your Samba username:"
read -er smb_usr
echo
set_password "Samba" "smb_passwd"
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

DISK=/dev/sda

wipefs -a -f "${DISK}"

### BIOS with GPT
parted --script "${DISK}" mklabel gpt
parted --script "${DISK}" mkpart ext2 1MiB 2MiB
parted --script "${DISK}" set 1 bios_grub on
parted --script "${DISK}" mkpart btrfs 2MiB 100%
partprobe "${DISK}"
mkfs.ext4 -F -L nixos "${DISK}"2

### BIOS with MBR
# parted --script "${DISK}" mklabel msdos
# parted --script "${DISK}" mkpart primary ext4 1MiB 100%
# parted --script "${DISK}" set 1 boot on
# partprobe "${DISK}"
# mkfs.ext4 -F -L nixos "${DISK}"1

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
