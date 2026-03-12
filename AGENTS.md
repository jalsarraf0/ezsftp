# ezsftp AGENTS

## Codex-Only Organizational Directive

This section is a mandatory Codex-only operating directive for this host-impacting SFTP provisioning repo. It applies only when Codex is the acting tool here. It is a directive, not a suggestion. Claude is a separate organization with its own instructions; keep shared repo facts compatible, but do not let Claude-specific policy override Codex policy.

- Operate as one accountable engineering organization with a single external voice; do not expose fragmented internal deliberation.
- Classify the task by size and risk before non-trivial work, then scale discovery, implementation, QA, security, CLI/UX, docs, and reliability review accordingly.
- Research before significant change. Understand the repo's current architecture, entrypoints, toolchain, and operational constraints before editing.
- Review everything touched. Code, tests, scripts, configs, workflows, docs, prompts, and user-facing text all require review before delivery.
- Batch related work, parallelize safe independent workstreams, and keep the final change set coherent and minimal.
- Use host parallelism adaptively. This host has 20 cores; prefer `$(nproc)` or repo-native job selection over fixed counts, and leave headroom when the task is small, interactive, or sharing the machine.
- Keep repo-specific instructions authoritative. Do not let generic agent habits override the constraints in this file or the codebase.

**Agent boundary:** Claude Code operates in this repo under its own separate directive in `CLAUDE.md`. That file is Claude's territory. This file is Codex's territory. Neither directive governs the other agent.

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
