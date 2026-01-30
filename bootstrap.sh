#!/bin/bash
# bootstrap.sh - One-command setup for Pi Serial Bridge
# 
# Usage:
#   curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
#
# Or with custom options:
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
INTERACTIVE=true

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
    -y, --yes               Non-interactive mode (use defaults or provided values)
    --help                  Show this help message

Examples:
    # Interactive mode (prompts for values)
    curl -sSL $GITHUB_REPO/bootstrap.sh | sudo bash

    # Non-interactive with playbook defaults
    curl -sSL $GITHUB_REPO/bootstrap.sh | sudo bash -s -- -y

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
        -y|--yes)      INTERACTIVE=false; shift ;;
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

# Prompt for configuration if interactive
prompt_config() {
    [[ "$INTERACTIVE" == "false" ]] && return 0
    [[ ! -t 0 ]] && { info "Non-interactive input detected, using defaults"; return 0; }
    
    echo ""
    echo "Configuration (press Enter for defaults from playbook.yml):"
    echo ""
    
    read -p "Hostname [russound-bridge]: " input
    [[ -n "$input" ]] && OPT_HOSTNAME="$input"
    
    read -p "Serial port [/dev/ttyUSB0]: " input
    [[ -n "$input" ]] && OPT_SERIAL="$input"
    
    read -p "TCP port [4999]: " input
    [[ -n "$input" ]] && OPT_PORT="$input"
    
    read -p "Baud rate [19200]: " input
    [[ -n "$input" ]] && OPT_BAUD="$input"
}

# Build extra-vars string (only for user-specified values)
build_extra_vars() {
    local vars=""
    [[ -n "$OPT_HOSTNAME" ]] && vars+="hostname=$OPT_HOSTNAME "
    [[ -n "$OPT_SERIAL" ]] && vars+="serial_port=$OPT_SERIAL "
    [[ -n "$OPT_PORT" ]] && vars+="tcp_port=$OPT_PORT "
    [[ -n "$OPT_BAUD" ]] && vars+="baudrate=$OPT_BAUD "
    echo "$vars"
}

# Main execution
install_ansible

info "Downloading playbook..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

curl -sSL "$GITHUB_REPO/playbook.yml" -o playbook.yml || error "Failed to download playbook"

prompt_config

EXTRA_VARS=$(build_extra_vars)

echo ""
if [[ -n "$EXTRA_VARS" ]]; then
    info "Running playbook with overrides: $EXTRA_VARS"
else
    info "Running playbook with defaults"
fi
echo ""

# Run playbook locally
ansible-playbook \
    --inventory "localhost," \
    --connection local \
    ${EXTRA_VARS:+-e "$EXTRA_VARS"} \
    playbook.yml

echo ""
info "Setup complete!"
info "Check status: sudo systemctl status ser2net"
