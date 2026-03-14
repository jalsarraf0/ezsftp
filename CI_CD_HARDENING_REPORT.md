# CI/CD Hardening Report — ezsftp

**Date:** 2026-03-14
**Branch:** `ci/assurance-hardening`
**Baseline:** `main` (clean)

---

## Changes Applied

### 1. Executable Permission Fix

- **Issue:** `ezsftp.sh` had mode `644` (not executable). Users running `./ezsftp.sh` would get "Permission denied".
- **Fix:** `git update-index --chmod=+x ezsftp.sh` — sets the executable bit in the Git index so all clones receive the correct permission.
- **Risk:** None. This is a metadata-only change.

### 2. shfmt Format Validation (ci.yml)

- **Added:** `shfmt` format check step in the `static` batch of Regression CI.
- **Configuration:** `shfmt -d -i 2 -ci -bn` (2-space indent, case indent, binary ops on next line).
- **Mode:** `continue-on-error: true` — advisory only until the codebase is formatted to match. This prevents CI breakage while allowing visibility into formatting drift.
- **Binary source:** Downloaded from the official mvdan/sh GitHub release (v3.11.0).

### 3. SBOM Generation Workflow (sbom.yml)

- **New workflow:** `.github/workflows/sbom.yml`
- **Triggers:** Push to `main`, weekly schedule (Monday 04:30 UTC), manual dispatch.
- **Output:** CycloneDX 1.5 JSON manifest containing project metadata, component list, and SHA-256 hash of `ezsftp.sh`.
- **Artifact retention:** 90 days.
- **Permissions:** `contents: read` only.
- **Concurrency:** Grouped to prevent duplicate runs.

### 4. Assurance Documentation (ASSURANCE.md)

- **New file:** Documents all CI/CD controls, static analysis, secret scanning, functional testing, supply chain practices, and the permissions model.
- **Purpose:** Provides a single reference for the project's quality and security posture.

### 5. README Badge Review

- **Status:** Existing badges for Regression CI and Security CI are correct and functional. No changes needed.
- **Note:** SBOM badge not added — the workflow produces an artifact, not a pass/fail status badge.

---

## Pre-Existing Controls (Unchanged)

| Control | Status |
|---|---|
| ShellCheck in Regression CI | Active |
| ShellCheck in Security CI | Active |
| Gitleaks secret scanning | Active |
| CodeQL for Actions | Active |
| DRY_RUN functional tests | Active |
| Concurrency groups | Active |
| Least-privilege permissions | Active |

---

## Risk Assessment

| Item | Risk | Mitigation |
|---|---|---|
| shfmt may flag existing code | Low | `continue-on-error: true` prevents CI failure |
| SBOM uses `/proc/sys/kernel/random/uuid` | Low | Standard Linux kernel interface; available on all CI runners |
| shfmt binary downloaded at runtime | Low | Pinned to specific version; downloaded over HTTPS from GitHub releases |

---

## Validation

- [ ] `bash -n ezsftp.sh` — syntax check
- [ ] `shellcheck ezsftp.sh` — lint
- [ ] YAML syntax valid for all workflow files
- [ ] `git diff --cached` confirms executable bit change
- [ ] No secrets in committed files
