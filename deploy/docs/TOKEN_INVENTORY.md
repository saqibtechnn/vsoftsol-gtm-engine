# Token & Credential Inventory

Filled in during Phase D1. Every credential the system holds appears here — no exceptions.
**Never record a secret value in this file.** Record where it lives, not what it is.

| # | Credential | Purpose | Scope (exact) | Owner | Storage location | Rotation interval | Revocation procedure | Last rotated |
|---|---|---|---|---|---|---|---|---|
| 1 | GitHub App / fine-grained PAT | Open PRs on the site repo | <repos, permissions> | | | 90 days | | |
| 2 | Vercel token | Read preview deployments | <project scope> | | | 90 days | | |
| 3 | Anthropic API key | Agent inference | <usage limit> | | | 90 days | | |
| 4 | Postgres app role | Application data access | Least privilege, no superuser | | | 180 days | | |
| 5 | Redis password | Queue access | Host-local only | | | 180 days | | |
| 6 | Email provider API key | Outbound sending | Send only, no account admin | | | 90 days | | |
| 7 | Cloudflare token | Tunnel + DNS | <minimum scope> | | | 90 days | | |
| 8 | GHCR token | Image push/pull | <repo scope> | | | 90 days | | |
| 9 | Social app credentials | Posting | Post only, minimum scopes | | | 90 days | | |
| 10 | Object storage key | Backups, artefacts | Bucket-scoped | | | 180 days | | |

## Scope verification record
For each credential, the out-of-scope action attempted in D1 and the denial observed:

| # | Out-of-scope action attempted | Result | Evidence |
|---|---|---|---|
