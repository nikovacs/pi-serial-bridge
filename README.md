# pi-serial-bridge

A simple bootstrap file to quickly setup a serial-tcp bridge on an SBC (Single Board Computer) like Raspberry Pi.

## Purpose

This project provides an easy way to bridge a serial device (such as a Russound sound system) to TCP/IP for use with Home Assistant or other network-based automation systems. It uses the standard `ser2net` tool for reliable serial-to-TCP bridging.

## Quick Start

Run the following command on your Raspberry Pi or similar SBC to automatically set up the serial-TCP bridge:

```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
```

The script will:
- Install required system packages (ser2net)
- Set up the hostname for easy network discovery
- Configure ser2net for serial-to-TCP bridging
- Set up and start a systemd service
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
sudo systemctl status ser2net.service
```

View logs:
```bash
sudo journalctl -u ser2net.service -f
```

Restart service:
```bash
sudo systemctl restart ser2net.service
```

Edit configuration:
```bash
sudo nano /etc/ser2net.yaml
sudo systemctl restart ser2net.service
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
