# Repository Guidelines

## Project Structure & Module Organization
- `goad.py` is the CLI entrypoint; `goad/` holds core logic (commands, providers, provisioners, instances).
- `ansible/` contains playbooks and roles; `playbooks.yml` defines the playbook order per lab.
- `ad/` stores lab definitions, data, scripts, and provider overlays; `extensions/` adds optional lab extensions.
- `template/` holds provider templates copied into `workspace/` at instance creation; `packer/` and `vagrant/` contain image/provider tooling.
- `docs/` (notably `docs/mkdocs/docs`) is the documentation source; `workspace/` is generated and should stay uncommitted.

## Build, Test, and Development Commands
- `./goad.sh` bootstraps `~/.goad/.venv`, installs Python + Ansible Galaxy deps, and launches the interactive console.
- `./goad.sh -t check -l GOAD -p virtualbox` verifies provider dependencies.
- `python3 goad.py -t install -l GOAD -p virtualbox` runs a single install task without the interactive console.
- `poetry run python3 goad.py` is an alternative when using Poetry for the Python environment.

## Coding Style & Naming Conventions
- Python uses 4-space indentation, `snake_case` for functions/variables, `CamelCase` for classes, and `UPPER_CASE` for constants.
- YAML/Ansible uses 2-space indentation; keep playbook names consistent with the existing `*-servers.yml`/`*-data.yml` patterns in `ansible/`.
- New lab assets live under `ad/<LAB>/...`; extensions go in `extensions/<extension>/...` with their own `ansible/` and `inventory` files.

## Testing Guidelines
- There is no automated unit test suite in this repo.
- For changes, at minimum run `./goad.sh -t check` and validate the affected lab/provider path (for example, a targeted playbook or full install in a disposable environment).

## Commit & Pull Request Guidelines
- Git history uses short, direct summaries (for example, `update doc`); keep commits concise and scoped.
- PRs should describe the lab/provider touched, any infra prerequisites, and the verification performed. Update docs in `docs/mkdocs/docs` when setup steps or behavior change.

## Security & Configuration Notes
- This lab is intentionally vulnerable; never deploy it on the public internet.
- Local configuration lives in `~/.goad/goad.ini`; do not commit credentials or generated instance state from `workspace/`.
