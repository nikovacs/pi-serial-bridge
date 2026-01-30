# pi-serial-bridge

A simple bootstrap file to quickly setup a serial-tcp bridge on an SBC (Single Board Computer) like Raspberry Pi.

## Purpose

This project provides an easy way to bridge a serial device (such as a Russound sound system) to TCP/IP for use with Home Assistant or other network-based automation systems.

## Quick Start

Run the following command on your Raspberry Pi or similar SBC to automatically set up the serial-TCP bridge:

```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
```

The script will:
- Install Python3 and required dependencies (pyserial)
- Set up the hostname for easy network discovery
- Configure and start a systemd service that bridges your serial device to TCP
- Provide configuration options for serial port, TCP port, and baud rate

## Configuration

During installation, you'll be prompted for:
- **Hostname**: Default is `russound-bridge` (accessible as `russound-bridge.local`)
- **Serial Port**: Default is `/dev/ttyUSB0`
- **TCP Port**: Default is `4999`
- **Baud Rate**: Default is `19200` (common for Russound systems)

## Usage with Home Assistant

After installation, configure your Home Assistant integration with:
- **Host**: `<your-hostname>.local` (e.g., `russound-bridge.local`)
- **Port**: `4999` (or your configured TCP port)

## Service Management

Check service status:
```bash
sudo systemctl status serial-tcp-bridge.service
```

View logs:
```bash
sudo journalctl -u serial-tcp-bridge.service -f
```

Restart service:
```bash
sudo systemctl restart serial-tcp-bridge.service
```

## Manual Installation

If you prefer to review the script before running it:

1. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh
   ```

2. Review the script:
   ```bash
   cat bootstrap.sh
   ```

3. Run it:
   ```bash
   sudo bash bootstrap.sh
   ```
