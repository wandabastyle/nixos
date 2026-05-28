# NixOS Configuration

NixOS flake for `loq15arp9`.

This configuration is intended for a fresh install and uses `disko` to partition the internal NVMe drive.

## Warning

The install layout wipes this disk:

```sh
/dev/nvme0n1
```

Check `lsblk` before running `disko`.

## Layout

- Stable base: `nixos-25.11`
- Host: `loq15arp9`
- Disk: GPT, UEFI, Btrfs
- Subvolumes: `@`, `@home`, `@nix`, `@log`
- Swap: zram only
- Login: SDDM password login
- Session: Niri Wayland session
- GPU: proprietary NVIDIA driver for RTX 4060 Laptop GPU
- Home config: Home Manager
- Dotfiles: mutable symlinks from `~/dotfiles/.config/*`

## Pre-Install: Export Keys

Before booting the NixOS ISO, export GPG and SSH keys on your current system:

```sh
# Export GPG secret keys (encrypted output)
gpg --export-secret-keys --armor > ~/secret-keys.asc
gpg --export-ownertrust > ~/gpg-ownertrust.txt

# Backup SSH keys (private + public)
mkdir -p ~/ssh-backup
cp ~/.ssh/id_* ~/ssh-backup/ 2>/dev/null || echo "No SSH keys in ~/.ssh"
```

## Install

Boot a NixOS installer ISO and connect networking.

For Wi-Fi:

```sh
nmtui
```

### Optional: Continue Over SSH

Set a temporary root password for SSH:

```sh
sudo passwd root
```

Start SSH if it is not already running:

```sh
sudo systemctl start sshd
```

Find the installer IP address:

```sh
ip addr
```

From another machine, connect to the installer:

```sh
ssh root@<installer-ip>
```

Continue the remaining install steps from the SSH session.

Commands below use `sudo`. If you are connected as `root` over SSH, omit `sudo`.

### Clone Repo

```sh
git clone --recurse-submodules <repo-url> ~/dotfiles
cd ~/dotfiles
```

### Confirm Target Disk

```sh
lsblk
```

### Partition And Format

```sh
sudo nix --extra-experimental-features "nix-command flakes" --accept-flake-config run github:nix-community/disko -- \
  --mode disko ./hosts/loq15arp9/disko.nix
```

### Install NixOS

```sh
sudo nixos-install --flake .#loq15arp9 --accept-flake-config
```

### Set User Password

Set the `kanashi` password before rebooting. No password is stored in this repo.

```sh
sudo nixos-enter
passwd kanashi
exit
```

### Reboot

```sh
reboot
```

## After First Boot

Log in through SDDM as `kanashi`.

### Import Keys

Import your GPG and SSH keys after first boot:

```sh
# Import GPG keys
gpg --import ~/secret-keys.asc
gpg --import-ownertrust ~/gpg-ownertrust.txt

# Restore SSH keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp ~/ssh-backup/id_* ~/.ssh/
chmod 600 ~/.ssh/id_*
```

### Clone Password Store

Once SSH and GPG are ready, clone your password store:

```sh
# Replace with your actual repository URL
git clone git@github.com:your-user/pass-store ~/.password-store
```

### Setup Dotfiles Repo

Make sure this repo exists at the canonical path:

```sh
~/dotfiles
```

If needed, clone or update submodules:

```sh
cd ~/dotfiles
git submodule update --init --recursive
```

Rebuild with:

```sh
sudo nixos-rebuild switch --flake ~/dotfiles#loq15arp9
```

## Dotfiles

Home Manager dynamically links every directory under:

```sh
~/dotfiles/.config/*
```

It intentionally excludes:

```sh
~/dotfiles/.config/systemd
```

User systemd services are declared in `home/kanashi.nix` instead of symlinked.

## User Services

Mirrored Home Manager user services:

- `nirinit.service`
- `ollama.service`
- `ollama-stop.service`
- `ollama-stop.timer`
- `updates-counter.service`
- `updates-counter.timer`

The updates counter writes the same file expected by the current shell setup:

```sh
~/.cache/updates-count
```

It counts changed flake inputs, not individual packages.

## Ollama

The config uses `ollama-cuda` for NVIDIA GPU support.

Your Neovim script falls back to:

```sh
qwen2.5-coder:7b
```

Ollama can pull models on first use. To prefetch manually:

```sh
ollama pull qwen2.5-coder:7b
```

## SDDM Theme

The current modified Tokyo Night SDDM theme is vendored in:

```sh
assets/sddm/tokyo-night-sddm
```

The configured wallpaper is:

```sh
Backgrounds/wp6265738.png
```
