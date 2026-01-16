<!--
Sync Impact Report
Version change: template → 1.0.0
Modified principles: initialized (Isolation & Risk Control; Deterministic Provisioning via GOAD CLI; Provider Parity & Template Integrity; Data & Inventory Source of Truth; Documentation, Coding Discipline & Verification)
Added sections: Operational Constraints & Stack; Development Workflow & Quality Gates; Governance (populated)
Removed sections: None
Templates requiring updates: .specify/templates/plan-template.md ✅; .specify/templates/spec-template.md ✅; .specify/templates/tasks-template.md ✅; command templates ⚠ (no command templates present)
Follow-up TODOs: None
-->

# GOAD Constitution

## Core Principles

### I. Isolation & Risk Control (Non-Negotiable)
Lab assets are intentionally vulnerable and MUST stay isolated from the public internet or untrusted networks; default to provider private networks and avoid inbound exposure unless explicitly documented, time-bound, and approved. Credentials, keys, and configuration secrets live only in local settings (for example `~/.goad/goad.ini` and per-instance `workspace/<id>/ssh_keys`) and are never committed. Cloud usage must include scoped IP ranges and teardown steps. Rationale: prevents unintended leakage of an intentionally insecure lab and limits blast radius.

### II. Deterministic Provisioning via GOAD CLI
All lab lifecycle actions (install, provide, provision) run through `./goad.sh` or `python3 goad.py`; do not hand-edit generated `workspace/` artifacts beyond ephemeral debugging, and never commit them. Provider artifacts originate from `template/<provider>/` merged with `ad/<lab>/providers/<provider>/` and optional `extensions/<extension>/providers/<provider>/`; edit those sources instead of generated outputs. Run `./goad.sh -t check -l <LAB> -p <PROVIDER>` before merging changes that affect provisioning or dependencies. Rationale: keeps builds reproducible across users and providers.

### III. Provider Parity & Template Integrity
When altering provisioning logic, evaluate and document parity across supported providers (virtualbox, vmware, proxmox, azure, aws, ludus); intentional divergences must be called out in docs. Templates, packer, vagrant, and terraform assets stay minimal and override-friendly; avoid embedding provider-specific logic in shared playbooks unless guarded. Breaking provider compatibility requires migration notes and justification. Rationale: maintains consistent lab behavior regardless of provider and reduces drift.

### IV. Data & Inventory Source of Truth
Lab data belongs in `ad/<lab>/data/config.json`; extension-specific data in `extensions/<extension>/data/config.json`; do not duplicate or hardcode these values in playbooks. Preserve inventory precedence: lab inventory → provider workspace inventory → extension inventories → `globalsettings.ini`; avoid modifying the base lab inventory structure. Treat `workspace/<instance>/...` as ephemeral state never committed or used as canonical data. Rationale: predictable overrides ensure deterministic provisioning and reliable debugging.

### V. Documentation, Coding Discipline & Verification
Behavioral or interface changes MUST update `docs/mkdocs/docs/` and `README.md` with provider-specific impacts and usage notes. Follow repo style (Python 4-space indentation, snake_case; Ansible/YAML 2-space indentation) and keep secrets or generated assets out of version control (`workspace/` remains ignored). Minimal verification is required: run the relevant `./goad.sh -t check` for the affected lab/provider, plus targeted playbook or provider smoke tests when feasible, and record results. Rationale: documentation and basic validation keep a dangerous lab usable and trustworthy.

## Operational Constraints & Stack

GOAD is a vulnerable Active Directory lab delivered via provider-specific virtual infrastructure. The managed entrypoints are `./goad.sh` (bootstrap plus interactive console) or `python3 goad.py` for targeted tasks; `goad_docker.sh` is available when isolating Ansible dependencies. Providers include virtualbox, vmware, proxmox, azure, aws, and ludus; proxmox and ludus require template preparation before provisioning. Instances live under `workspace/<instance_id>/` with merged provider files and inventories; these artifacts are generated and must remain uncommitted. Global overrides reside in `globalsettings.ini`, while user defaults live in `~/.goad/goad.ini`.

## Development Workflow & Quality Gates

During design, declare the lab(s), provider(s), and extensions affected, along with any required isolation or exposure windows. Implement changes in source locations (`ad/<lab>/...`, `extensions/<extension>/...`, `template/<provider>/`, `ansible/`, `playbooks.yml`) rather than generated workspace files, and preserve playbook ordering. Before review, run `./goad.sh -t check -l <LAB> -p <PROVIDER>` for each affected provider and note any targeted playbook runs or smoke validations. Every change that alters behavior includes a documentation update and a brief verification note in the change description.

## Governance

This constitution supersedes other practice guides for GOAD delivery. Amendments require a documented rationale, an update to this file with version bump, and any necessary migration or testing notes; semantic versioning applies (MAJOR for incompatible governance changes, MINOR for new principles or material expansions, PATCH for clarifications). `RATIFICATION_DATE` records the initial adoption; `LAST_AMENDED_DATE` updates with each change. Reviews must include a Constitution Check confirming isolation controls, reproducible provisioning via GOAD CLI, provider parity considerations, data and inventory source-of-truth usage, documentation updates, and recorded verification. Template files under `.specify/templates/` must be updated alongside governance changes to keep tooling aligned.

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
