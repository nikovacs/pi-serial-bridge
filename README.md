# pi-serial-bridge

A simple setup tool to quickly configure a serial-to-TCP bridge on an SBC (Single Board Computer) like Raspberry Pi.

## Purpose

This project provides an easy way to bridge a serial device (such as a Russound sound system) to TCP/IP for use with Home Assistant or other network-based automation systems. It uses the standard `ser2net` tool for reliable serial-to-TCP bridging.

**Single Source of Truth**: All configuration logic lives in the Ansible playbook (`playbook.yml`). The bootstrap script is just a thin wrapper that installs Ansible and runs the playbook.

## Installation Methods

### Method 1: Ansible Playbook (Direct)

Run the Ansible playbook directly for full control and multi-host deployment.

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
- **Single Source of Truth**: All configuration logic in one place (playbook.yml)
- **Idempotent**: Safe to run multiple times without causing issues
- **Configuration as Code**: Easily version control your settings
- **Multi-host Deployment**: Configure multiple devices simultaneously
- **Better Error Handling**: Built-in rollback capabilities

### Method 2: Bootstrap Script (Quick Setup)

For a quick setup with a single curl command:


Run this command on your Raspberry Pi:

```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
```

**What it does:**
1. Installs Ansible if not present
2. Downloads the playbook and configuration files
3. Prompts for your configuration (hostname, ports, etc.)
4. Runs the Ansible playbook in local mode

**Note:** The bootstrap script is a thin wrapper around the Ansible playbook. All configuration logic lives in `playbook.yml` to avoid duplication.

## What Gets Configured

The Ansible playbook configures:
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

- **playbook.yml**: **Single source of truth** - ALL configuration logic lives here
- **bootstrap.sh**: Thin wrapper that installs Ansible and runs the playbook
- **vars.yml**: Default configuration variables
- **inventory.ini**: Ansible inventory file (edit to add your hosts)
- **ansible.cfg**: Ansible configuration
- **setup-ansible.sh**: Helper script to install Ansible on control machine
- **ARCHITECTURE.md**: Detailed explanation of the single source of truth architecture
- **README.md**: This file

## Architecture

This project follows a **single source of truth** principle:

- **playbook.yml** contains ALL configuration logic (installing packages, configuring services, etc.)
- **bootstrap.sh** is a minimal wrapper (~139 lines) that:
  1. Installs Ansible if needed
  2. Downloads playbook files
  3. Prompts for configuration
  4. Runs ansible-playbook

This eliminates code duplication and ensures there's only one place to maintain configuration logic.
