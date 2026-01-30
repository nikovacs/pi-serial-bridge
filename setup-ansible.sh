#!/bin/bash
# Quick setup script for Ansible-based deployment
# This script installs Ansible and runs the playbook

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[INFO]${NC} Installing Ansible..."

# Detect OS and install Ansible
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu/Raspberry Pi OS
    sudo apt-get update -qq
    sudo apt-get install -y ansible
elif command -v dnf &> /dev/null; then
    # Fedora
    sudo dnf install -y ansible
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    sudo yum install -y ansible
elif command -v pacman &> /dev/null; then
    # Arch Linux
    sudo pacman -S --noconfirm ansible
else
    echo -e "${YELLOW}[WARNING]${NC} Could not detect package manager. Please install Ansible manually."
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Ansible installed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit inventory.ini to add your target host(s)"
echo "2. Edit vars.yml to customize configuration"
echo "3. Run: ansible-playbook playbook.yml"
echo ""
echo "For more information, see README.md"
