# Pi Serial Bridge

One-command setup for a serial-to-TCP bridge on Raspberry Pi OS, Debian, or Ubuntu.

## Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash
```

That's it! The script will:
1. Install Ansible (if needed)
2. Prompt for configuration (hostname, ports, etc.)
3. Install and configure `ser2net` for serial-to-TCP bridging
4. Set up automatic security updates

## Non-Interactive Mode

Use defaults without prompts:
```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash -s -- -y
```

Custom configuration:
```bash
curl -sSL https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/bootstrap.sh | sudo bash -s -- \
    --hostname mybridge \
    --port 5000 \
    --serial /dev/ttyAMA0 \
    --baud 9600
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-h, --hostname` | Device hostname | `russound-bridge` |
| `-p, --port` | TCP port | `4999` |
| `-s, --serial` | Serial device | `/dev/ttyUSB0` |
| `-b, --baud` | Baud rate | `19200` |
| `-y, --yes` | Non-interactive mode | - |

## What Gets Configured

- **ser2net**: Serial-to-TCP bridge service
- **Hostname**: Accessible as `<hostname>.local` via mDNS
- **Auto-updates**: Security updates every Monday at 4:30am (with auto-reboot if needed)

## Usage with Home Assistant

After installation, configure your Home Assistant integration:
- **Host**: `<hostname>.local` (e.g., `russound-bridge.local`)
- **Port**: `4999` (or your configured port)

## Service Management

```bash
# Check status
sudo systemctl status ser2net

# View logs
sudo journalctl -u ser2net -f

# Restart service
sudo systemctl restart ser2net

# Edit configuration
sudo nano /etc/ser2net.yaml
sudo systemctl restart ser2net
```

## Advanced: Run Ansible Directly

For multi-host deployment or more control, run the playbook directly:

```bash
# Download playbook
curl -O https://raw.githubusercontent.com/nikovacs/pi-serial-bridge/main/playbook.yml

# Run against remote host
ansible-playbook playbook.yml \
    -i "192.168.1.100," \
    -u pi \
    -e "hostname=mybridge tcp_port=5000"
```

## Files

| File | Purpose |
|------|---------|
| `bootstrap.sh` | One-command installer (curl this) |
| `playbook.yml` | Ansible playbook - single source of truth for all config logic and defaults |

## License

MIT
