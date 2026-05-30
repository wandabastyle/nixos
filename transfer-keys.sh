#!/usr/bin/env bash

# Transfer SSH config to NixOS ISO for install
# Run this on your old system targeting the NixOS ISO

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fixed configuration for ISO user
SSH_USER="nixos"

# Ask for IP
echo -e "${YELLOW}Transfer SSH config to NixOS ISO${NC}"
echo ""
read -rp "Enter the IP address of the NixOS ISO: " NIXOS_IP

if [[ -z "$NIXOS_IP" ]]; then
    echo -e "${RED}Error: IP address is required${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Target: ${SSH_USER}@${NIXOS_IP}${NC}"
echo -e "${YELLOW}Note: You'll be prompted for the 'nixos' password${NC}"
echo ""

# Transfer SSH config
echo -e "${YELLOW}Transferring SSH configuration...${NC}"
ssh "${SSH_USER}@${NIXOS_IP}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp -r "$HOME/.ssh/." "${SSH_USER}@${NIXOS_IP}:~/.ssh/"

# Set permissions
echo -e "${YELLOW}Setting SSH permissions...${NC}"
ssh "${SSH_USER}@${NIXOS_IP}" '
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_* 2>/dev/null || true
    chmod 644 ~/.ssh/*.pub 2>/dev/null || true
    chmod 644 ~/.ssh/config 2>/dev/null || true
    chmod 644 ~/.ssh/known_hosts 2>/dev/null || true
    echo "SSH config transferred"
'

echo -e "${GREEN}✓ SSH configuration transferred!${NC}"
echo ""
echo -e "${YELLOW}Next: Clone dotfiles manually on the ISO (requires interactive SSH auth)${NC}"
echo ""
echo "Run these commands on the ISO:"
echo ""
echo "  1. SSH into the ISO:"
echo "     ssh nixos@${NIXOS_IP}"
echo ""
echo "  2. Start SSH agent and add your key (you'll be prompted for passphrase):"
echo "     eval \"\$(ssh-agent -s)\""
echo "     ssh-add"
echo ""
echo "  3. Clone dotfiles with submodules:"
echo "     git clone --recurse-submodules https://github.com/wandabastyle/nixos ~/dotfiles"
echo ""
echo "  4. Proceed with install:"
echo "     cd ~/dotfiles"
echo "     sudo nix --extra-experimental-features 'nix-command flakes' \\"
echo "       --option extra-substituters 'https://noctalia.cachix.org' \\"
echo "       --option trusted-public-keys 'noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=' \\"
echo "       run github:nix-community/disko -- --mode disko ./hosts/loq15arp9-vm/disko.nix"
echo "     sudo nixos-install --flake .#loq15arp9-vm"
echo "     sudo nixos-enter; passwd kanashi; exit"
echo "     reboot"
echo ""
echo "After first boot, SSH and dotfiles will be in /home/kanashi (via activation script)"
echo ""
