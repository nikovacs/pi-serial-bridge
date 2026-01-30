# Architecture: Single Source of Truth

## Problem Solved

Previously, we had **duplicate configuration logic** in two places:
- `bootstrap.sh` (210 lines) - bash implementation
- `playbook.yml` (152 lines) - Ansible implementation

This meant:
❌ Changes had to be made twice
❌ Risk of configurations drifting apart
❌ More code to maintain and test

## Solution

```
┌─────────────────────────────────────────────────┐
│         Single Source of Truth                  │
│                                                  │
│         playbook.yml (152 lines)                │
│         • Install ser2net                       │
│         • Install unattended-upgrades           │
│         • Configure automatic updates           │
│         • Set hostname                          │
│         • Configure ser2net                     │
│         • Manage services                       │
└─────────────────────────────────────────────────┘
                      ▲
                      │
                      │ uses
                      │
┌─────────────────────────────────────────────────┐
│         bootstrap.sh (139 lines)                │
│         Thin wrapper that:                      │
│         1. Installs Ansible                     │
│         2. Downloads playbook files             │
│         3. Prompts for configuration            │
│         4. Runs ansible-playbook                │
└─────────────────────────────────────────────────┘
```

## Benefits

✅ **No Duplication**: Configuration logic exists in exactly one place
✅ **Single Maintenance**: Changes only need to be made to playbook.yml
✅ **Consistency**: Impossible for implementations to drift apart
✅ **Flexibility**: Bootstrap still provides curl|bash convenience
✅ **Less Code**: Reduced from 362 total lines to 291 (20% reduction)

## Usage Comparison

### Before (Duplicate Logic)
```bash
# Both scripts implemented all configuration independently
bootstrap.sh      # 210 lines of config logic
playbook.yml      # 152 lines of config logic
# Total: 362 lines, duplicate maintenance burden
```

### After (Single Source of Truth)
```bash
# Bootstrap delegates to playbook
bootstrap.sh      # 139 lines (just Ansible wrapper)
playbook.yml      # 152 lines (all config logic)
# Total: 291 lines, single maintenance point
```

## File Roles

| File | Role | Lines | Purpose |
|------|------|-------|---------|
| playbook.yml | **Master** | 152 | ALL configuration logic |
| bootstrap.sh | **Wrapper** | 139 | Install Ansible, run playbook |
| vars.yml | Config | 20 | Default variable values |
| inventory.ini | Config | 5 | Host definitions |

## The Key Principle

> **"Don't Repeat Yourself" (DRY)**
> 
> Configuration logic exists in exactly ONE place: `playbook.yml`
> 
> Everything else is just orchestration to run that playbook.
