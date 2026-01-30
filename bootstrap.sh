#!/bin/bash
# bootstrap.sh - Setup script for Raspberry Pi Serial TCP Bridge
# This script can be downloaded and run with:
# curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_HOSTNAME="russound-bridge"
DEFAULT_SERIAL_PORT="/dev/ttyUSB0"
DEFAULT_TCP_PORT="4999"
DEFAULT_BAUDRATE="19200"

# Function to print colored messages
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

print_info "Starting Pi Serial Bridge bootstrap..."

# Update package lists
print_info "Updating package lists..."
apt-get update -qq

# Install ser2net (standard serial-to-network tool)
print_info "Installing ser2net..."
apt-get install -y ser2net

# Set hostname
read -p "Enter hostname for this device [${DEFAULT_HOSTNAME}]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}

if [ "$(hostname)" != "$HOSTNAME" ]; then
    print_info "Setting hostname to: $HOSTNAME"
    hostnamectl set-hostname "$HOSTNAME"
    
    # Update /etc/hosts
    if ! grep -q "127.0.1.1.*$HOSTNAME" /etc/hosts; then
        sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/g" /etc/hosts
        if ! grep -q "127.0.1.1" /etc/hosts; then
            echo "127.0.1.1	$HOSTNAME" >> /etc/hosts
        fi
    fi
    print_info "Hostname set to: $HOSTNAME"
else
    print_info "Hostname is already set to: $HOSTNAME"
fi

# Prompt for serial configuration
read -p "Enter serial port [${DEFAULT_SERIAL_PORT}]: " SERIAL_PORT
SERIAL_PORT=${SERIAL_PORT:-$DEFAULT_SERIAL_PORT}

read -p "Enter TCP port [${DEFAULT_TCP_PORT}]: " TCP_PORT
TCP_PORT=${TCP_PORT:-$DEFAULT_TCP_PORT}

read -p "Enter baud rate [${DEFAULT_BAUDRATE}]: " BAUDRATE
BAUDRATE=${BAUDRATE:-$DEFAULT_BAUDRATE}

# Create ser2net configuration file
print_info "Creating ser2net configuration..."

cat > /etc/ser2net.yaml <<EOF
connection: &con01
  accepter: tcp,${TCP_PORT}
  connector: serialdev,${SERIAL_PORT},${BAUDRATE}n81,local
  options:
    kickolduser: true
EOF

# Reload systemd and enable the service
print_info "Enabling and starting ser2net service..."
systemctl daemon-reload
systemctl enable ser2net.service
systemctl restart ser2net.service

# Check service status
sleep 2
if systemctl is-active --quiet ser2net.service; then
    print_info "Serial TCP Bridge service is running successfully!"
else
    print_warning "Service may not be running. Check status with: systemctl status ser2net.service"
fi

# Display configuration summary
echo ""
echo "======================================"
echo "  Configuration Summary"
echo "======================================"
echo "Hostname:     $HOSTNAME"
echo "Serial Port:  $SERIAL_PORT"
echo "TCP Port:     $TCP_PORT"
echo "Baud Rate:    $BAUDRATE"
echo "======================================"
echo ""
print_info "Setup complete! The serial bridge is now available at: ${HOSTNAME}.local:${TCP_PORT}"
print_info "You can check the service status with: systemctl status ser2net.service"
print_info "View logs with: journalctl -u ser2net.service -f"
echo ""
print_info "For Home Assistant, use:"
echo "  Host: ${HOSTNAME}.local"
echo "  Port: ${TCP_PORT}"
