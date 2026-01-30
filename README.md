# pi-serial-bridge

A simple setup tool to quickly configure a serial-to-TCP bridge on an SBC (Single Board Computer) like Raspberry Pi. Available as both an Ansible playbook (recommended) and a bash script.

## Purpose

This project provides an easy way to bridge a serial device (such as a Russound sound system) to TCP/IP for use with Home Assistant or other network-based automation systems. It uses the standard `ser2net` tool for reliable serial-to-TCP bridging.

## Installation Methods

> **💡 Quick Answer:** Both methods do the same thing! The Ansible playbook includes all functionality from the bootstrap script (ser2net, unattended-upgrades, etc.). See [DIAGRAM.md](DIAGRAM.md) for a visual comparison.

### Method 1: Ansible Playbook (Recommended)

The Ansible playbook provides a more maintainable, idempotent approach suitable for managing multiple devices. **It includes all the same functionality as the bootstrap script** (installing ser2net, configuring unattended-upgrades, etc.) but in a declarative, repeatable format.

#### Prerequisites
- Ansible installed on your control machine (or run `./setup-ansible.sh` to install)
- SSH access to your target Raspberry Pi

#### Quick Start

1. Clone or download this repository
2. Edit `inventory.ini` to specify your target host:
   ```ini
   [pi_serial_bridge]
   192.168.1.100 ansible_user=pi
   ```

3. (Optional) Customize configuration in `vars.yml`:
   ```yaml
   hostname: "russound-bridge"
   serial_port: "/dev/ttyUSB0"
   tcp_port: 4999
   baudrate: 19200
   ```

4. Run the playbook:
   ```bash
   ansible-playbook playbook.yml
   ```

   Or with custom variables:
   ```bash
   ansible-playbook playbook.yml -e @vars.yml
   ```

#### Ansible Features
- **Complete Replacement**: Includes all bootstrap.sh functionality (ser2net, unattended-upgrades, etc.)
- **Idempotent**: Safe to run multiple times without causing issues
- **Configuration as Code**: Easily version control your settings
- **Multi-host Deployment**: Configure multiple devices simultaneously
- **Better Error Handling**: Built-in rollback capabilities

### Method 2: Bash Script (Quick One-Time Setup)

For a quick, one-time setup on a single device:


Run the following command on your Raspberry Pi to automatically set up the serial-TCP bridge:

```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
```

The script will:
- Install required system packages (ser2net, unattended-upgrades)
- Configure automatic OS updates (Mondays at 4:30am)
- Set up the hostname for easy network discovery
- Configure ser2net for serial-to-TCP bridging
- Set up and start a systemd service
- Provide interactive prompts for configuration

**Note:** The bash script is provided for quick, one-time setups. For production use or managing multiple devices, the Ansible playbook is recommended.

## What Gets Configured

Both installation methods configure:
- **Hostname**: Default is `russound-bridge` (accessible as `russound-bridge.local`)
- **Serial Port**: Default is `/dev/ttyUSB0`
- **TCP Port**: Default is `4999`
- **Baud Rate**: Default is `19200` (common for Russound systems)
- **Automatic Updates**: Security updates run Mondays at 4:30am
- **Auto-reboot**: System reboots automatically at 4:30am if updates require it

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

## Automatic Updates

The bootstrap script configures automatic security updates for Debian, Ubuntu, and Raspberry Pi OS variants:

- **Schedule**: Updates run automatically every Monday at 4:30am
- **Scope**: Security updates and critical patches
- **Reboot**: System will automatically reboot if required (at 4:30am)
- **Cleanup**: Unused packages and old kernels are automatically removed

To check automatic update status:
```bash
sudo systemctl status apt-daily-upgrade.timer
```

To manually trigger an update:
```bash
sudo unattended-upgrade -d
```

To modify the update schedule, edit:
```bash
sudo nano /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart apt-daily-upgrade.timer
```

## Manual Installation

If you prefer to review the bash script before running it:

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

## Files in This Repository

- **playbook.yml**: Main Ansible playbook for configuration
- **vars.yml**: Configuration variables for the playbook
- **inventory.ini**: Ansible inventory file (edit to add your hosts)
- **ansible.cfg**: Ansible configuration
- **setup-ansible.sh**: Helper script to install Ansible
- **bootstrap.sh**: Standalone bash script for quick setup
- **COMPARISON.md**: Detailed comparison between Ansible and bash approaches
- **README.md**: This file

## FAQ

### Does the Ansible playbook replace the bootstrap script?

**Yes!** The Ansible playbook includes all the functionality from the bootstrap script:

- ✅ Installs ser2net
- ✅ Installs and configures unattended-upgrades  
- ✅ Sets up automatic security updates (Mondays at 4:30am)
- ✅ Configures hostname
- ✅ Creates ser2net configuration
- ✅ Manages all systemd services

The playbook is the **recommended** method for production use. The bootstrap script remains available for users who need a quick, one-time setup without installing Ansible.

See [COMPARISON.md](COMPARISON.md) for a detailed side-by-side comparison.
