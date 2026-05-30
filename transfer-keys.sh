#!/usr/bin/env bash

# Transfer keys from old system to new NixOS machine
# Run this on your current (old) system after NixOS is installed and booted

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME"
SSH_BACKUP_DIR="$HOME/ssh-backup"
GPG_ASC="$BACKUP_DIR/secret-keys.asc"
GPG_TRUST="$BACKUP_DIR/gpg-ownertrust.txt"

# Ask for IP and user
echo -e "${YELLOW}Transfer keys to new NixOS machine${NC}"
echo ""
read -rp "Enter the IP address of your new NixOS machine: " NIXOS_IP
read -rp "Enter the SSH username [kanashi]: " SSH_USER
SSH_USER=${SSH_USER:-kanashi}

if [[ -z "$NIXOS_IP" ]]; then
    echo -e "${RED}Error: IP address is required${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Target: ${SSH_USER}@${NIXOS_IP}${NC}"
echo ""

# Check if backup files exist locally
if [[ ! -d "$SSH_BACKUP_DIR" ]]; then
    echo -e "${YELLOW}Warning: SSH backup directory not found: $SSH_BACKUP_DIR${NC}"
    echo "SSH config may already be on the new system from install phase"
    echo ""
fi

# Only require GPG files if not using ISO user
if [[ "$SSH_USER" != "nixos" ]]; then
    missing_gpg=false
    
    if [[ ! -f "$GPG_ASC" ]]; then
        echo -e "${RED}Error: GPG key backup not found: $GPG_ASC${NC}"
        echo "Run 'gpg --export-secret-keys --armor > ~/secret-keys.asc' first"
        missing_gpg=true
    fi
    
    if [[ ! -f "$GPG_TRUST" ]]; then
        echo -e "${RED}Error: GPG ownertrust not found: $GPG_TRUST${NC}"
        echo "Run 'gpg --export-ownertrust > ~/gpg-ownertrust.txt' first"
        missing_gpg=true
    fi
    
    if [[ "$missing_gpg" == true ]]; then
        exit 1
    fi
fi

# Ask for password upfront (if using password auth)
if [[ "$SSH_USER" == "nixos" ]]; then
    echo -e "${YELLOW}Note: Using password authentication for ISO user 'nixos'${NC}"
    echo -e "${YELLOW}You'll be prompted for the password during each SSH operation${NC}"
    echo ""
fi

# Skip connection test for password auth to avoid multiple prompts
if [[ "$SSH_USER" != "nixos" ]]; then
    echo -e "${YELLOW}Testing SSH key connection...${NC}"
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -q "${SSH_USER}@${NIXOS_IP}" exit 2>/dev/null; then
        echo -e "${RED}Error: Cannot connect to ${SSH_USER}@${NIXOS_IP} via SSH key${NC}"
        echo "Make sure:"
        echo "  1. The NixOS machine is running and on the network"
        echo "  2. SSH is enabled (systemctl status sshd)"
        echo "  3. Your SSH key is authorized on the new machine"
        exit 1
    fi
    echo -e "${GREEN}SSH connection successful!${NC}"
    echo ""
fi

# Transfer SSH config directly from ~/.ssh on host
if [[ -d "$HOME/.ssh" ]]; then
    echo -e "${YELLOW}Transferring SSH configuration from ~/.ssh...${NC}"
    # Copy entire ~/.ssh directory directly to remote
    scp -r "$HOME/.ssh/" "${SSH_USER}@${NIXOS_IP}:~/"
    
    # Setup SSH directory permissions on remote
    echo -e "${YELLOW}Setting up SSH directory permissions on remote...${NC}"
    ssh "${SSH_USER}@${NIXOS_IP}" << 'REMOTE_CMDS'
        if [[ -d ~/.ssh ]]; then
            chmod 700 ~/.ssh
            chmod 600 ~/.ssh/id_* 2>/dev/null || true
            chmod 644 ~/.ssh/*.pub 2>/dev/null || true
            chmod 644 ~/.ssh/config 2>/dev/null || true
            chmod 644 ~/.ssh/known_hosts 2>/dev/null || true
            chmod 644 ~/.ssh/authorized_keys 2>/dev/null || true
            echo "SSH config restored successfully"
            echo "Files in ~/.ssh:"
            ls -la ~/.ssh/ | head -20
        fi
        
        # Configure git credential helper if git is available
        if command -v git >/dev/null 2>&1; then
            git config --global credential.helper store
            echo "Git credential helper configured"
        fi
REMOTE_CMDS
    
    # Start SSH agent on ISO to cache passphrase for submodule clones
    if [[ "$SSH_USER" == "nixos" ]]; then
        echo ""
        echo -e "${YELLOW}Starting SSH agent for submodule authentication...${NC}"
        ssh "${SSH_USER}@${NIXOS_IP}" << 'REMOTE_CMDS'
            # Start agent if not running
            if ! pgrep -u "$(whoami)" ssh-agent >/dev/null 2>&1; then
                eval "$(ssh-agent -s)"
            fi
            # Add all keys
            for key in ~/.ssh/id_*; do
                [[ "$key" == *.pub ]] && continue
                [[ -f "$key" ]] && ssh-add "$key" 2>/dev/null || true
            done
            echo "SSH agent started"
            echo "NOTE: You may be prompted for your SSH key passphrase"
REMOTE_CMDS
    fi
    
    echo -e "${GREEN}SSH configuration transferred!${NC}"
    echo ""
fi

# Transfer GPG keys (skip import for ISO user since GPG isn't available)
if [[ "$SSH_USER" == "nixos" ]]; then
    echo -e "${YELLOW}Skipping GPG import for ISO user (GPG not available on ISO)${NC}"
    echo -e "${YELLOW}Transfer GPG keys after first boot using: ./transfer-keys.sh${NC}"
else
    echo -e "${YELLOW}Transferring GPG keys...${NC}"
    scp "$GPG_ASC" "$GPG_TRUST" "${SSH_USER}@${NIXOS_IP}:~/"
    
    # Import GPG keys on remote
    echo ""
    echo -e "${YELLOW}Importing GPG keys on remote machine...${NC}"
    ssh "${SSH_USER}@${NIXOS_IP}" << 'REMOTE_CMDS'
        echo "Importing GPG secret keys..."
        gpg --import ~/secret-keys.asc
        
        echo "Importing GPG ownertrust..."
        gpg --import-ownertrust ~/gpg-ownertrust.txt
        
        echo "Configuring git credential helper..."
        git config --global credential.helper store
        
        echo "Cleaning up transferred files..."
        rm -f ~/secret-keys.asc ~/gpg-ownertrust.txt
        
        echo "GPG setup complete!"
REMOTE_CMDS
fi

# Clone dotfiles repo with submodules if it doesn't exist
echo -e "${YELLOW}Checking for dotfiles repo...${NC}"
ssh "${SSH_USER}@${NIXOS_IP}" << 'REMOTE_CMDS'
    if [[ ! -d ~/dotfiles ]]; then
        echo "Cloning dotfiles repo with submodules..."
        git clone --recurse-submodules https://github.com/wandabastyle/nixos ~/dotfiles
        echo "Dotfiles cloned successfully!"
    else
        echo "Dotfiles repo already exists at ~/dotfiles"
        cd ~/dotfiles
        git submodule update --init --recursive
        echo "Submodules updated!"
    fi
REMOTE_CMDS

echo ""
echo -e "${GREEN}✓ All keys transferred and configured successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Clone your password store:"
echo "     git clone git@github.com:your-user/pass-store ~/.password-store"
echo ""
echo "  2. Rebuild NixOS if needed:"
echo "     sudo nixos-rebuild switch --flake ~/dotfiles#loq15arp9"
echo ""
