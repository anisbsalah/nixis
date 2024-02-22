# NIXIS: NixOS Installation Script

A one-shot script to install NixOS on my personal machine.

## Installation steps

### 1. Download NixOS ISO

Download the NixOS ISO from <https://nixos.org/download/> and put it on a USB drive with [Etcher](https://www.balena.io/etcher/), [Rufus](https://rufus.ie/en/), or [Ventoy](https://www.ventoy.net/en/index.html).

### 2. Boot NixOS ISO

### 3. Log in as root

```bash
sudo -i
```

### 4. Set the console keyboard layout and font

```bash
loadkeys fr
```

```bash
setfont ter-v20b
```

### 5. Connect to the internet

```bash
systemctl start wpa_supplicant.service
```

```bash
wpa_cli
```

```bash
add_network
```

```bash
set_network 0 ssid "myhomenetwork"
```

```bash
set_network 0 psk "mypassword"
```

```bash
set_network 0 key_mgmt WPA-PSK
```

```bash
enable_network 0
```

```bash
quit
```

### 6. Run the installation script

```bash
bash <(curl -L https://github.com/anisbsalah/nixis/raw/main/nixis.sh)
```

### 7. Reboot

### 8. Change user password & Set root password

- Initial user password: `password`

```bash
sudo passwd <username>
```

```bash
sudo passwd root
```
