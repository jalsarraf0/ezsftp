# Assurance — ezsftp

This document describes the quality and security assurance controls in place for the ezsftp project.

---

## CI/CD Pipeline

| Workflow | Trigger | Purpose |
|---|---|---|
| **Regression CI** (`ci.yml`) | push, PR, manual | Syntax validation (`bash -n`), ShellCheck lint, shfmt format check, DRY_RUN functional tests |
| **Security CI** (`security.yml`) | push, PR, manual, weekly | Gitleaks secret scanning, ShellCheck security analysis, CodeQL for GitHub Actions |
| **SBOM Generation** (`sbom.yml`) | push to main, weekly, manual | CycloneDX software bill of materials for supply chain transparency |

All CI jobs run on self-hosted runners: `[self-hosted, Linux, X64, docker]`.

---

## Static Analysis

- **ShellCheck**: Enforced in both Regression CI and Security CI. Catches common Bash pitfalls, quoting issues, and security-relevant patterns.
- **shfmt**: Format consistency check (continue-on-error while baseline is established). Uses `shfmt -d -i 2 -ci -bn`.
- **bash -n**: Syntax parse validation before any further checks.

---

## Secret Scanning

- **Gitleaks** v8.24.3 runs on every push and PR with full history scan (`fetch-depth: 0`).
- Repository-level `.gitignore` excludes common secret file patterns.

---

## Functional Testing

- **DRY_RUN flow**: The CI creates a temporary directory structure and runs `ezsftp.sh` with `DRY_RUN=1` for both `add` and `remove` actions, verifying the script completes without error in a sandboxed environment.

---

## Supply Chain

- **SBOM**: CycloneDX 1.5 manifest generated weekly and on push to main. Includes SHA-256 hash of `ezsftp.sh`. Uploaded as a CI artifact with 90-day retention.
- **Pinned actions**: All GitHub Actions are pinned to major versions (`@v4`).

---

## Permissions Model

- All workflows use `permissions: contents: read` (least privilege).
- CodeQL job additionally requests `security-events: write` (required by GitHub).
- Concurrency groups prevent redundant parallel runs.

---

## File Integrity

| File | Expected Mode | Notes |
|---|---|---|
| `ezsftp.sh` | `755` (executable) | Main script; must be executable for direct invocation |
| `.github/scripts/*.sh` | `755` | CI helper scripts |

---

## Validation Checklist

Before merging any change:

1. `bash -n ezsftp.sh` passes
2. `shellcheck ezsftp.sh` passes
3. DRY_RUN add/remove flow succeeds
4. No secrets detected by gitleaks
5. shfmt reports no drift (advisory)
