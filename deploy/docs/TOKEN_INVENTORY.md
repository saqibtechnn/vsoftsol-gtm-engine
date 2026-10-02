# Token & Credential Inventory

Filled in during Phase D1 (2026-10-02). Every credential the system holds appears here — no exceptions.
**Never record a secret value in this file.** Record where it lives, not what it is.
Design rationale: `deploy/docs/IDENTITY_AND_ACCESS.md`.

**State** column: `DESIGNED` (scope fixed, not yet created) · `CREATED` (exists; scope test pending) · `VERIFIED` (out-of-scope denial and revocation both evidenced) · `N/A` (not created by decision) · `BLOCKED` · `OPEN`.
"Owner" = the person accountable for the credential. In this deployment that is always the VSoftSol owner (`saqibtechnn`); RACI.md.

## A. System credentials (held by VGE components or its pipelines)

| # | Credential | State | Purpose | Scope (exact) | Owner | Storage location | Rotation interval | Revocation procedure | Last rotated |
|---|---|---|---|---|---|---|---|---|---|
| 1 | GitHub App `vge-site-bot` private key (+ 1-hour installation tokens minted from it) | DESIGNED | Open PRs with generated content on the site repo | Installed on **`saqibtechnn/vsoftsol-website` only** ("Only select repositories"). Repository permissions: Contents **read & write**, Pull requests **read & write**, Metadata read (mandatory). All other permissions **No access**. No account permissions. Webhook **inactive**. "Where can this app be installed": **Only on this account** | Owner | Production: SOPS-encrypted in git (D5), decrypted to tmpfs, mounted into `dispatcher` only (DECISIONS #14). Never in staging | 90 days (generate new key → deploy → delete old key) | App settings → *Private keys* → **Delete** the key (immediate). Emergency: *Install App* → **Uninstall** from the repo, or `gh api -X DELETE /app/installations/<id>` with the App JWT. Installation tokens: `DELETE /installation/token` (tested by `verify_github_app_scope.sh` check 10–11) | — |
| 2 | Vercel token `vge-vercel-preview-read` | OPEN | Read preview deployment status for VGE PRs | Project scope: the site project only. **First choice: not created** — VGE reads the Vercel commit status on the PR through credential #1 instead | Owner | If created: SOPS (D5), `dispatcher` only | 90 days | Vercel → Account Settings → Tokens → **Delete** | — |
| 3 | Anthropic API key | N/A | Agent inference | Not created: LLM provider deferred (DECISIONS #16, condition C8) | — | — | — | — | — |
| 4 | Postgres app role `vge_app` | DESIGNED (created in D4) | Application data access | `LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION`; DML on `vge` schema only; no DDL (migrations run as a separate `vge_migrator` role) | Owner | SOPS (D5) → tmpfs → app containers | 180 days | `ALTER ROLE vge_app NOLOGIN;` then terminate sessions: `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename='vge_app';` | — |
| 5 | Redis password | DESIGNED (created in D4) | Queue access | Host-internal Compose network only; ACL user `vge` with `-@admin -@dangerous` | Owner | SOPS (D5) → tmpfs | 180 days | `ACL SETUSER vge off` + restart clients | — |
| 6 | Email provider API key | N/A | Outbound sending | Not created: draft-only, owner hand-sends (DECISIONS #7) | — | — | — | — | — |
| 7a | Cloudflare account-owned API token `vge-tofu-dns` | OPEN (only if vsoftsol.com DNS is on Cloudflare, A6) | OpenTofu: DNS records for vsoftsol.com | Account-owned token. Permissions: **Zone → DNS → Edit** on the vsoftsol.com zone only. No tunnel or Access permissions (DECISIONS #25). TTL 90 days | Owner | Owner's Codespaces secret (user-level, restricted to the VGE repo). Never on the host | 90 days (TTL forces it) | Cloudflare → Manage Account → Account API Tokens → **Roll** or **Delete** | — |
| 7b | ~~Cloudflare tunnel token `vge-prod-tunnel`~~ | N/A | Superseded: no Cloudflare Tunnel (DECISIONS #25) | — | — | — | — | — | — |
| 7c | ~~Cloudflare tunnel token `vge-staging-tunnel`~~ | N/A | Superseded: staging uses Codespaces private port forwarding (DECISIONS #25) | — | — | — | — | — | — |
| 8 | GHCR push | DESIGNED (D3/D9) | Push images | **No stored token.** GitHub Actions `GITHUB_TOKEN` with `packages: write` on the VGE repo's own package, per job, expires at job end. Pull on the host: decided in D3 (public package needs no credential; anything else is added to this inventory then) | Owner | Not stored | n/a (per-job) | Disable workflow / remove `packages: write` from the workflow | — |
| 9 | Social app credentials | N/A (OPEN) | Posting | Not created: platforms not decided (A7) | — | — | — | — | — |
| 10a | OCI API key — user `vge-tofu` | DESIGNED | OpenTofu provisioning (D2) | Group `vge-provisioners`, policy `Allow group vge-provisioners to manage all-resources in compartment vge where request.permission != 'BASTION_SESSION_CREATE'` (may build the bastion, may **not** open sessions into the host — DECISIONS #25). No console password, no auth tokens, no customer secret keys, no SMTP creds. MFA n/a (API-key-only user) | Owner | Owner's Codespaces secret (PEM + fingerprint). Never on the host | 90 days | Identity → Users → `vge-tofu` → API keys → **Delete**; emergency: **Block** the user (`oci iam user update-user-state --user-id <ocid> --blocked true`) | — |
| 10b | OCI customer secret key — user `vge-backup` | DESIGNED (created in D4; skipped if instance principal works) | WAL-G / dumps to Object Storage (S3-compatible) | Group `vge-backup-writers`, policy `Allow group vge-backup-writers to manage objects in compartment vge where target.bucket.name='vge-backups'` + `read buckets` on the same bucket. No delete-bucket, no lifecycle edit | Owner | SOPS (D5) → tmpfs → `wal-g` | 180 days | Users → `vge-backup` → Customer secret keys → **Delete** | — |
| 10c | OCI dynamic group `vge-prod-host` (instance principal) | DESIGNED (D2) | Host access to OCI APIs without a stored key | `instance.compartment.id = '<vge ocid>'` and instance tag `vge:role=prod`; policy as 10b | Owner | No secret exists | n/a | Delete the policy statement or the dynamic group | — |
| 11 | Off-provider backup copy key (B2 or equivalent) | DESIGNED (D4) | Second backup copy (DECISIONS #3) | Application key restricted to one bucket, `writeFiles` + `listFiles` only (no delete) | Owner | SOPS (D5) | 180 days | B2 → App Keys → **Delete** | — |
| 12 | Owner release-signing key (DECISIONS #19) | DESIGNED (D6) | Sign production release manifests | Signs manifests only; the host trusts its public key | Owner | Owner's hardware key or offline storage; never in CI or on the host | On compromise only (+ yearly review) | Remove the public key from the host's trust file via Ansible; re-sign current manifest with the new key | — |
| 13 | age key (SOPS) | DESIGNED (D5) | Decrypt secrets at boot | Production recipient only; staging has its own key | Owner | Host tmpfs at boot from owner-held source; sealed offline copy for break-glass | 365 days or on compromise | Re-encrypt all files to a new recipient (`sops updatekeys`), destroy old key | — |
| 14 | OCI Bastion session SSH key | DESIGNED (first used in D2) | Owner reaches the production console (port-forward to caddy :443) | One key pair **per session**; session TTL ≤ 3 h; port-forwarding to the host private IP :443 only; sessions creatable only by the Administrators group (owner) after MFA login | Owner | Generated on the owner device per session (`ssh-keygen -t ed25519 -f /tmp/vge-bastion-<date> -N ''`), deleted after the session | Per session | Session expires on its own at TTL; early: `oci bastion session delete --session-id <ocid>`; all access: delete the bastion (`oci bastion bastion delete`) | — |

## B. Human accounts in the path (not machine credentials; listed so access reviews cover them)

| Account | Holder | MFA | Role in system | Evidence |
|---|---|---|---|---|
| GitHub `saqibtechnn` | Owner | **OPEN** — not readable with current token | Owns repos, App, rulesets; approves PRs | Owner screenshot of *Settings → Password and authentication* (runbook §1) |
| OCI tenancy administrator | Owner | **OPEN** | Tenancy admin; creates IAM users | Runbook §2 |
| Cloudflare account (only if DNS host, A6) | Owner | **OPEN** | Super admin; DNS only | Runbook §3 |
| Vercel account | Owner | **OPEN** | Hosts site; deploys from `main` | Runbook §5 |

No VGE runtime component authenticates as any account in this table.

## C. Operator-workstation credentials (outside the system path; recorded because they can reach it)

| Credential | Scope observed | Risk | Action |
|---|---|---|---|
| GitHub CLI OAuth token on owner PC (`gho_****REDACTED****`, keyring) | `repo`, `read:org`, `gist` — read/write on **every** repo of the account (`gh auth status`, 2026-10-02) | Any Claude Code session or malware on the PC can push to any repo the ruleset does not cover (incl. a private VGE repo) | Owner decision (OPEN): keep (needed to apply rulesets) or `gh auth refresh --remove-scopes ...`/re-login with narrower scope after D1. Rulesets on the site repo apply to this token too |

## Scope verification record
For each credential, the out-of-scope action attempted in D1 and the denial observed.
Scripts: `deploy/scripts/d1/`. Rows are filled with real output only.

| # | Out-of-scope action attempted | Result | Evidence |
|---|---|---|---|
| 1 | 9 denials + token revocation (`verify_github_app_scope.sh`) | NOT RUN — credential not created | — |
| 7a | Single-zone visibility, zone-settings / members / Access / Workers / tokens denials (`verify_cloudflare_token_scope.sh`) | NOT RUN — token not created (A6 OPEN) | — |
| 10a | Root-compartment and IAM reads (`verify_oci_scope.sh`, `vge-tofu`) | NOT RUN — credential not created | — |
| 14 | Bastion session creation by `vge-tofu` denied (`verify_oci_scope.sh` check 7) | NOT RUN — OCI not set up | — |
| Site ruleset | Direct push to `main` (`verify_site_push_blocked.sh`) | Ruleset applied 2026-10-02 (id 24366860; deletion, non_fast_forward, required_signatures, pull_request active on `main`). Push test **NOT RUN**: Claude Code permission classifier denied the live push; owner to run | PHASE_D1_VERIFICATION §4 |

## Revocation test record
Each credential type gets one create → revoke → confirm-rejected cycle with a throwaway credential of the same type, before the real one is relied on.

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | Installation token revoked → 401 (script checks 10–11); throwaway App key deleted → JWT rejected | NOT RUN | — |
| 7a | Throwaway account token with same perms deleted → `/tokens/verify` 401 | NOT RUN | — |
| 10a | Throwaway API key deleted → `oci os ns get` NotAuthenticated | NOT RUN | — |
