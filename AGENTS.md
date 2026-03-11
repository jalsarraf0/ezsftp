# ezsftp AGENTS

## What This Repo Does

`ezsftp.sh` provisions and removes chrooted SFTP-only users. It manages Linux users and groups, chroot directories, SSH keys, `/etc/fstab` entries, and SSHD config fragments.

## Main Entrypoints

- `ezsftp.sh`: the project.
- `README.md`: operator-facing behavior and examples.

## Commands

- `bash ezsftp.sh --help`
- `bash ezsftp.sh --dry-run`
- `shellcheck ezsftp.sh`
- `bash -n ezsftp.sh`

## Repo-Specific Constraints

- Live runs require root.
- Always prefer `--dry-run` before live changes.
- Keep dry-run semantics strict: no writes to users, chroots, `fstab`, or SSHD config.
- Use SSHD fragments rather than editing the main `sshd_config`.
- Real changes should be followed by `sshd -t` on the target host.

## Agent Notes

- Treat this repo as host-impacting automation.
- Keep changes minimal and preserve idempotence.
