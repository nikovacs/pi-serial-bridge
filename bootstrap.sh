#!/bin/bash
# bootstrap.sh - One-command setup for Pi Serial Bridge
# 
# Usage:
#   curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
#
# With custom options:
#   curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash -s -- \
#       --hostname mybridge --port 5000 --serial /dev/ttyAMA0 --baud 9600
#
# Supports: Raspberry Pi OS, Debian, Ubuntu
#
# Defaults are defined in playbook.yml (single source of truth)

set -e

GITHUB_REPO="https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main"
WORK_DIR="/tmp/pi-serial-bridge-$$"

# User overrides (empty = use playbook defaults)
OPT_HOSTNAME=""
OPT_SERIAL=""
OPT_PORT=""
OPT_BAUD=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
cleanup() { rm -rf "$WORK_DIR" 2>/dev/null || true; }

trap cleanup EXIT

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --hostname NAME     Set hostname (default: russound-bridge)
    -p, --port PORT         Set TCP port (default: 4999)
    -s, --serial DEVICE     Set serial port (default: /dev/ttyUSB0)
    -b, --baud RATE         Set baud rate (default: 19200)
    --help                  Show this help message

Examples:
    # Use defaults
    curl -sSL $GITHUB_REPO/bootstrap.sh | sudo bash

    # Custom configuration
    curl -sSL $GITHUB_REPO/bootstrap.sh | sudo bash -s -- \\
        --hostname mybridge --port 5000 --serial /dev/ttyAMA0
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--hostname) OPT_HOSTNAME="$2"; shift 2 ;;
        -p|--port)     OPT_PORT="$2"; shift 2 ;;
        -s|--serial)   OPT_SERIAL="$2"; shift 2 ;;
        -b|--baud)     OPT_BAUD="$2"; shift 2 ;;
        --help)        usage ;;
        *)             error "Unknown option: $1. Use --help for usage." ;;
    esac
done

[[ $EUID -ne 0 ]] && error "This script must be run as root (use sudo)"

echo ""
info "Pi Serial Bridge Setup"
echo "========================================"

# Install Ansible if needed
install_ansible() {
    if command -v ansible-playbook &>/dev/null; then
        info "Ansible already installed"
        return 0
    fi

    info "Installing Ansible..."
    
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        apt-get install -y ansible
    elif command -v dnf &>/dev/null; then
        dnf install -y ansible
    elif command -v yum &>/dev/null; then
        yum install -y ansible
    else
        error "Unsupported package manager. Install Ansible manually."
    fi
    
    info "Ansible installed"
}

# Build extra-vars string (only for user-specified values)
build_extra_vars() {
    local vars=""
    if [[ -n "$OPT_HOSTNAME" ]]; then vars+="hostname=$OPT_HOSTNAME "; fi
    if [[ -n "$OPT_SERIAL" ]]; then vars+="serial_port=$OPT_SERIAL "; fi
    if [[ -n "$OPT_PORT" ]]; then vars+="tcp_port=$OPT_PORT "; fi
    if [[ -n "$OPT_BAUD" ]]; then vars+="baudrate=$OPT_BAUD "; fi
    echo "$vars"
}

# Prompt for config if no flags provided and terminal available
prompt_if_interactive() {
    # Skip if any flags were provided
    if [[ -n "$OPT_HOSTNAME$OPT_SERIAL$OPT_PORT$OPT_BAUD" ]]; then return 0; fi
    # Skip if no terminal available
    if [[ ! -e /dev/tty ]]; then return 0; fi
    
    echo ""
    echo "Configuration (press Enter for defaults):"
    
    read -p "  Hostname [russound-bridge]: " input < /dev/tty
    if [[ -n "$input" ]]; then OPT_HOSTNAME="$input"; fi
    
    read -p "  Serial port [/dev/ttyUSB0]: " input < /dev/tty
    if [[ -n "$input" ]]; then OPT_SERIAL="$input"; fi
    
    read -p "  TCP port [4999]: " input < /dev/tty
    if [[ -n "$input" ]]; then OPT_PORT="$input"; fi
    
    read -p "  Baud rate [19200]: " input < /dev/tty
    if [[ -n "$input" ]]; then OPT_BAUD="$input"; fi
}

# Main execution
install_ansible

info "Downloading playbook..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

curl -sSL "$GITHUB_REPO/playbook.yml" -o playbook.yml || error "Failed to download playbook"

prompt_if_interactive

EXTRA_VARS=$(build_extra_vars)

echo ""
if [[ -n "$EXTRA_VARS" ]]; then
    info "Running playbook with overrides: $EXTRA_VARS"
else
    info "Running playbook with defaults"
fi
echo ""

# Run playbook locally
if ! ansible-playbook \
    --inventory "localhost," \
    --connection local \
    ${EXTRA_VARS:+-e "$EXTRA_VARS"} \
    playbook.yml; then
    echo ""
    error "Playbook failed! See errors above."
fi

echo ""
info "Setup complete!"
info "Check status: sudo systemctl status ser2net"
