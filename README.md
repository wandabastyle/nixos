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
- Dotfiles: mutable symlinks from `~/nixos/dotfiles/.config/*`

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
git clone --recurse-submodules <repo-url> ~/nixos
cd ~/nixos
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

Make sure this repo exists at the canonical path:

```sh
~/nixos
```

If needed, clone or update submodules:

```sh
cd ~/nixos
git submodule update --init --recursive
```

Rebuild with:

```sh
sudo nixos-rebuild switch --flake ~/nixos#loq15arp9
```

## Dotfiles

Home Manager dynamically links every directory under:

```sh
~/nixos/dotfiles/.config/*
```

It intentionally excludes:

```sh
~/nixos/dotfiles/.config/systemd
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
