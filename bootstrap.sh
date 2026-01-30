#!/bin/bash
# bootstrap.sh - Minimal wrapper to run Ansible playbook for Pi Serial Bridge
# This script can be downloaded and run with:
# curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
#
# This is a thin wrapper that:
# 1. Installs Ansible if needed
# 2. Downloads the playbook and configuration files
# 3. Runs the playbook in local mode
# 
# All configuration logic lives in playbook.yml (single source of truth)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main"
WORK_DIR="/tmp/pi-serial-bridge-$$"

# Default values
DEFAULT_HOSTNAME="russound-bridge"
DEFAULT_SERIAL_PORT="/dev/ttyUSB0"
DEFAULT_TCP_PORT="4999"
DEFAULT_BAUDRATE="19200"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_info "Pi Serial Bridge Bootstrap (Ansible wrapper)"
echo ""

# Install Ansible if not present
if ! command -v ansible-playbook &> /dev/null; then
    print_info "Ansible not found. Installing Ansible..."
    
    # Detect OS and install Ansible
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu/Raspberry Pi OS
        apt-get update -qq
        apt-get install -y ansible
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf install -y ansible
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        yum install -y ansible
    else
        print_error "Could not detect package manager. Please install Ansible manually."
        exit 1
    fi
    
    print_info "Ansible installed successfully!"
else
    print_info "Ansible is already installed ($(ansible --version | head -1))"
fi

# Create temporary work directory
print_info "Setting up temporary workspace..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download playbook files
print_info "Downloading playbook files..."
curl -sSL "$GITHUB_REPO/playbook.yml" -o playbook.yml
curl -sSL "$GITHUB_REPO/vars.yml" -o vars.yml

# Create local inventory
cat > inventory.ini <<EOF
[local]
localhost ansible_connection=local
EOF

# Prompt for configuration (or accept defaults)
echo ""
echo "Configuration (press Enter to accept defaults):"
echo ""

read -p "Hostname [${DEFAULT_HOSTNAME}]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}

read -p "Serial port [${DEFAULT_SERIAL_PORT}]: " SERIAL_PORT
SERIAL_PORT=${SERIAL_PORT:-$DEFAULT_SERIAL_PORT}

read -p "TCP port [${DEFAULT_TCP_PORT}]: " TCP_PORT
TCP_PORT=${TCP_PORT:-$DEFAULT_TCP_PORT}

read -p "Baud rate [${DEFAULT_BAUDRATE}]: " BAUDRATE
BAUDRATE=${BAUDRATE:-$DEFAULT_BAUDRATE}

# Create custom vars file with user's configuration
cat > custom_vars.yml <<EOF
---
hostname: "${HOSTNAME}"
serial_port: "${SERIAL_PORT}"
tcp_port: ${TCP_PORT}
baudrate: ${BAUDRATE}
auto_update_schedule: "Mon *-*-* 04:30:00"
auto_update_reboot_time: "04:30"
EOF

echo ""
print_info "Running Ansible playbook with your configuration..."
echo ""

# Run the playbook
ansible-playbook \
    -i inventory.ini \
    -e @custom_vars.yml \
    playbook.yml

# Cleanup
cd /
rm -rf "$WORK_DIR"

echo ""
print_info "Bootstrap complete!"
print_info "Your serial bridge is now configured and running."
echo ""
