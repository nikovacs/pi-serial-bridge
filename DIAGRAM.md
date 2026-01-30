# Architecture Overview

## Both Methods Do The Same Thing

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  GOAL: Configure a Raspberry Pi as a Serial-to-TCP Bridge    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
    ┌───────────────────────┐   ┌──────────────────────┐
    │  Ansible Playbook     │   │  Bootstrap Script    │
    │  (Recommended)        │   │  (Quick Setup)       │
    └───────────────────────┘   └──────────────────────┘
                │                           │
                │                           │
                └─────────────┬─────────────┘
                              │
                              ▼
              ┌───────────────────────────┐
              │   What Gets Configured:   │
              ├───────────────────────────┤
              │ • Install ser2net         │
              │ • Install unattended-     │
              │   upgrades                │
              │ • Configure auto updates  │
              │   (Mon 4:30am)            │
              │ • Set hostname            │
              │ • Configure ser2net       │
              │ • Start services          │
              └───────────────────────────┘
```

## Key Differences

### Ansible Playbook
```
Characteristics:
├── Idempotent (safe to re-run)
├── Declarative configuration
├── Multi-host capable
├── Version controllable
└── Production ready

Use When:
├── Managing multiple devices
├── Need repeatable deployments
├── Want configuration as code
└── Production environments
```

### Bootstrap Script
```
Characteristics:
├── Interactive prompts
├── One-time execution
├── Simple curl | bash
├── No dependencies (except bash)
└── Single device focused

Use When:
├── Quick setup needed
├── Don't want to install Ansible
├── Single device
└── Testing/development
```

## The Answer

**Q: Does the playbook have steps for installing ser2net and unattended-upgrades?**

**A: YES! Absolutely!** The playbook includes ALL the same functionality:

| Component | Bootstrap Line | Playbook Line | Status |
|-----------|----------------|---------------|--------|
| Install ser2net | 46-47 | 19-22 | ✅ |
| Install unattended-upgrades | 52-53 | 24-27 | ✅ |
| Configure auto-updates | 56-98 | 29-81 | ✅ |
| Set hostname | 107-124 | 83-92 | ✅ |
| Configure ser2net | 168-177 | 94-105 | ✅ |
| Start services | 179-191 | 107-117 | ✅ |

The playbook **replaces** the bootstrap script with a better approach for production use.
