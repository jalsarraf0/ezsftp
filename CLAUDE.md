# CLAUDE.md — ezsftp

Single Bash script (`ezsftp.sh`) that provisions and revokes chrooted SFTP-only users.
Supports DRY-RUN mode. Version 1.6.

---

## Usage

```bash
# Show usage / man page
bash ezsftp.sh --help

# Dry-run (no changes written)
bash ezsftp.sh --dry-run --add <username>

# Provision a user
sudo bash ezsftp.sh --add <username>

# Revoke a user
sudo bash ezsftp.sh --remove <username>
```

---

## What the Script Manages

- Linux user + group (`sftpaccess` by default)
- Chroot directory under `${CHROOT_BASE:-/chroot}`
- Shared directory under `${SHARED_DIR:-/shared}`
- SSH key generation (OpenSSH + PuTTY formats) — keys land in `${KEY_DIR:-/root/created_keys}`
- `/etc/fstab` bind mounts
- SSHD config fragment under `/etc/ssh/sshd_config.d/`

---

## Configurable Defaults (env vars)

| Variable | Default | Purpose |
|---|---|---|
| `CHROOT_BASE` | `/chroot` | Root for chroot jails |
| `SHARED_DIR` | `/shared` | Shared directory |
| `GROUP_NAME` | `sftpaccess` | SFTP group |
| `KEY_DIR` | `/root/created_keys` | Where generated keys are stored |
| `FSTAB_FILE` | `/etc/fstab` | fstab path |
| `SSHD_FRAG_DIR` | `/etc/ssh/sshd_config.d` | SSHD config fragment dir |

---

## Safety Rules

- Always test with `--dry-run` before running for real.
- The script requires root. Run with `sudo`.
- SSHD config changes: the script writes a fragment file, not the main `sshd_config`.
  Validate syntax with `sshd -t` after any change.
- Revoke removes the user and their chroot — this is destructive. Dry-run first.

---

## Coding Conventions (maintain when editing)

- `#!/usr/bin/env bash` + `set -Eeuo pipefail`
- All logic in named functions.
- Colours via `tput` with terminal detection (`-t 1` guard).
- `--dry-run` flag must prevent any write to the filesystem, fstab, or sshd config.
- Validate required binaries at startup with `command -v`.

---

## Validation

```bash
shellcheck ezsftp.sh
sudo bash ezsftp.sh --dry-run --add testuser   # no actual changes
sshd -t                                         # syntax check after real provisioning
```

---

## Toolchain

| Tool | Path | Version |
|---|---|---|
| bash | `/usr/bin/bash` | system |
| shellcheck | `/usr/bin/shellcheck` | system (dnf) |
| Go | `/go/bin/go` | 1.26.1 — not used by this repo |
| Rust | `/usr/bin/rustc` | 1.93.1 — not used by this repo |
| Python | `/usr/bin/python3` | 3.14.3 — not used by this repo |

This repo is pure Bash. No build step required.
