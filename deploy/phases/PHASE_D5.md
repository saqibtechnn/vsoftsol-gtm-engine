# Phase D5 — Secrets & Configuration Management

**Lead subagent:** `secrets-custodian`
**Prerequisite:** D4 gate signed

## Objective
Correct configuration is enforced at startup, and no secret is ever at rest in plaintext.

## Deliverables
1. SOPS + age encrypted config per environment, safely committed. Age keys distributed and their storage documented.
2. Runtime secret injection from the provider secret store (or decrypted at boot into memory only) — never written to disk, never baked into an image.
3. Strict startup configuration validation (Pydantic settings) that **refuses to start** on a missing or malformed value. No silent defaults for anything that matters.
4. Environment feature flags, including the **staging send-guard** that restricts email recipients to an allowlist.
5. `deploy/runbooks/SECRET_ROTATION.md` — per-credential intervals, procedure, expected downtime window, verification after rotation.
6. Git history scanned with gitleaks and trufflehog; findings remediated and the remediation documented.
7. Log scrubbing filters for tokens, API keys, email addresses and personal data.
8. `.env.example` documenting every variable with a safe placeholder and a one-line description.

## Verification
- [ ] Remove each required secret in turn; confirm a **clear fail-fast error** every time, naming the missing variable.
- [ ] Confirm no secret appears in `docker inspect`, image layers, environment dumps, application logs or crash traces.
- [ ] Clean secret scan over **full git history**, not just the working tree.
- [ ] Rotate one live credential end to end using **only the runbook**; confirm downtime is within the documented window.
- [ ] Confirm log scrubbing works: log a test payload containing a fake token and an email address; confirm both are redacted downstream.

## Exit gate
Clean secret scan. Fail-fast proven for every required variable. Tag `deploy-v0.5.0`.
