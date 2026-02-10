# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GOAD (Game Of Active Directory) v3 is a pentest Active Directory lab framework that creates vulnerable but realistic AD environments for security training. It supports multiple infrastructure providers (cloud and local) with Ansible-based provisioning.

**Documentation**: https://orange-cyberdefense.github.io/GOAD/

## Common Commands

```bash
# Bootstrap and launch interactive console
./goad.sh

# Check provider dependencies
./goad.sh -t check -l GOAD -p virtualbox

# Non-interactive single command
python3 goad.py -t install -l GOAD -p virtualbox

# Poetry-based execution
poetry run python3 goad.py
```

## Architecture

### Core Flow
```
goad.py (CLI entry) → LabManager (singleton orchestrator)
                         ├── Labs (lab definitions from ad/)
                         ├── LabInstances (workspace management)
                         ├── Providers (infrastructure backends)
                         └── Provisioners (Ansible execution)
```

### Provider System
- **Terraform-based**: AWS, Azure, Aliyun, Proxmox (`goad/provider/terraform/`)
- **Vagrant-based**: VirtualBox, VMware, VMware ESXi, VMware vCenter (`goad/provider/vagrant/`)
- **Ludus**: Purpose-built lab platform (`goad/provider/ludus/`)
- Provider constants defined in `goad/utils.py`, factory in `goad/provider/provider_factory.py`

### Provisioning System
Ansible provisioners in `goad/provisioner/`: local, remote, runner, docker, vm
- Playbook sequences defined in `ansible/playbooks.yml`
- Roles in `ansible/roles/`

### Key Directories
- `goad/` - Python package (CLI, providers, provisioners, instance management)
- `ad/` - Lab definitions (GOAD, GOAD-Light, MINILAB, NHA, SCCM)
- `ansible/` - Playbooks and roles
- `extensions/` - Optional modules (ELK, Exchange, Guacamole, Wazuh)
- `template/provider/` - Provider templates copied to workspace on instance creation
- `workspace/` - Runtime instance data (git-ignored)

### Lab Structure
Each lab in `ad/<lab_name>/` contains:
- `data/config.json` - Lab configuration
- `data/inventory` - Ansible inventory
- `providers/<provider>/` - Provider-specific overrides

### Configuration
- User config: `~/.goad/goad.ini` (INI format with sections: default, aws, azure, aliyun, proxmox, ludus, vmware_esxi, vmware_vcenter)
- Config class: `goad/config.py`

## Coding Conventions

- Python: 4-space indentation, `snake_case` functions, `CamelCase` classes, `UPPER_CASE` constants
- YAML/Ansible: 2-space indentation
- Constants go in `goad/utils.py`
- New providers: implement base class, register in `provider_factory.py`, add templates to `template/provider/`

## Testing

No automated test suite. Validate changes with:
1. Run `./goad.sh -t check -l <lab> -p <provider>` for affected combinations
2. Test playbooks in isolated environment when modifying Ansible
3. Full install test for critical changes

## Adding New Components

### New Provider
1. Create `goad/provider/<type>/<name>.py` implementing provider interface
2. Add constant to `goad/utils.py` ALLOWED_PROVIDERS
3. Register in `goad/provider/provider_factory.py`
4. Add lab implementations in `ad/<lab>/providers/<name>/`
5. Create templates in `template/provider/<name>/`

### New Lab
1. Create `ad/<lab_name>/` with data/, providers/, scripts/, files/ structure
2. Define `data/config.json` and inventory
3. Add playbook sequence to `ansible/playbooks.yml`

## Security Warning

This lab is intentionally vulnerable. Never deploy on public internet or reuse configurations in production.

---

## Long-Running Deployment & Fault Recovery Strategy (MANDATORY)

Due to the lengthy nature of infrastructure deployment (often 30+ minutes to hours), the following strategies are **strictly required** to minimize wasted effort and preserve progress.

### 1. Error Handling - Retry Before Retreat

When encountering command execution errors during deployment:

1. **Immediate In-Place Retry**: Before reporting failure or suggesting rollback, retry the failed command 2-3 times with appropriate intervals (30s-60s). Many errors are transient (network timeouts, resource contention, cloud API throttling).

2. **Diagnose Root Cause**: If retries fail, investigate:
   - Check logs for specific error messages
   - Verify resource state (VM running? Network reachable? Service started?)
   - Identify if the error is recoverable vs. fatal

3. **Partial Recovery**: If one component fails, attempt to continue with remaining steps when possible. A failed secondary service shouldn't block primary infrastructure setup.

4. **Resume Points**: Use `--start-at-task` for Ansible or equivalent resume mechanisms rather than restarting from scratch.

### 2. Experience Documentation - Capture What You Learn

**When a problem is resolved, IMMEDIATELY document the solution:**

```bash
# Location: docs/mkdocs/docs/troobleshoot.md (SINGLE SOURCE OF TRUTH)
# Format:
# Problem: [Brief description]
# Symptom: [Error message or behavior]
# Root Cause: [Why it happened]
# Solution: [Commands or steps to fix]
# Prevention: [How to avoid in future]
```

**What to document:**
- Commands that needed adjustment for specific environments
- Timing issues requiring delays or retries
- Cloud provider-specific quirks (API limits, regional differences)
- Dependency order issues
- Workarounds for known bugs

### 3. Checkpoint & Snapshot Strategy - Enable Incremental Rollback

**CRITICAL: Never allow a situation where the only option is full rollback.**

#### Checkpoint Timing
Create snapshots/checkpoints at these stages:
1. **Post-Infrastructure**: After VMs/network are created, before any configuration
2. **Post-Domain-Setup**: After AD domain is functional
3. **Post-Each-Major-Role**: After each significant Ansible role completes
4. **Pre-Vulnerability-Injection**: Before applying intentional vulnerabilities

#### Implementation by Provider
```bash
# Terraform-based (AWS/Azure/Aliyun): Use terraform state snapshots
cp terraform.tfstate terraform.tfstate.checkpoint-<stage>

# VMware/ESXi: Use VM snapshots
# Proxmox: Use container/VM snapshots
# Vagrant: Use vagrant snapshot commands
vagrant snapshot save <vm_name> checkpoint-<stage>
```

#### Naming Convention
```
checkpoint-<stage>-<YYYYMMDD-HHMM>
# Examples:
# checkpoint-infra-ready-20240115-1430
# checkpoint-domain-joined-20240115-1545
# checkpoint-pre-vulns-20240115-1630
```

#### Rollback Decision Tree
```
Error Occurred
    │
    ├─► Is it transient? (network, timeout) ──► Retry 2-3 times
    │
    ├─► Is it configuration error? ──► Fix config, resume from current point
    │
    ├─► Is it state corruption? ──► Rollback to nearest checkpoint
    │
    └─► Is it infrastructure issue? ──► Rollback to post-infra checkpoint
                                        (preserve VM creation, redo config)
```

### 4. Deployment Workflow - Validate Incrementally

**Do NOT run a full deployment blindly. Use staged validation:**

```bash
# Stage 1: Infrastructure only
python3 goad.py -t install -l GOAD -p <provider>  # Stop after infra
# Validate: VMs accessible? Network configured?
# Checkpoint: snapshot here

# Stage 2: Domain setup
# Run domain-related playbooks
# Validate: Domain functional? DNS working?
# Checkpoint: snapshot here

# Stage 3: Full provisioning
# Continue with remaining playbooks
# Checkpoint: snapshot before vulnerability injection

# Stage 4: Final validation
# Run full validation suite
# Only after all stages pass, consider it complete
```

### 5. Final Verification - Always Re-run from Scratch

After successfully debugging and fixing issues:

1. **Document all fixes** in appropriate locations
2. **Create a clean test** - destroy and recreate from scratch using documented process
3. **Verify fixes are permanent** - ensure no manual interventions were missed
4. **Update scripts** - incorporate any manual fixes into automation

This ensures reproducibility and catches any undocumented manual steps.
