# Identity & Access Design (Phase D1)

Produced in Phase D1 (2026-10-02). Lead role: `security-engineer` (performed inline by the main thread, as in D0).
Budget: USD 0 (DECISIONS #23). Nothing in this document may introduce a charge.

Status markers: **OPEN** = owner input missing. **BLOCKED** = cannot be done as specified until an owner decision is made.

---

## 1. Plan

### Objective
Decide and record who and what can touch VGE before anything exists to touch: one identity per integration, the narrowest token that works, a tested revocation path for each, and an emergency path that is detectable.

### Deliverables → where they live
| # | Phase deliverable | Artefact | State at end of this session |
|---|---|---|---|
| 1 | Cloud account, MFA, billing alert at ceiling | `deploy/runbooks/D1_ACCOUNT_SETUP.md` §2 | Runbook written; owner executes (Claude may not log in) |
| 2 | Separate service identities per integration | §3 below | Designed; owner creates |
| 3 | GitHub branch protection, signed commits, env protection | §4 below, `ops/github/site-main-ruleset.json`, `deploy/scripts/d1/apply_site_ruleset.sh` | Site repo: ready to apply on owner confirmation. VGE repo: **BLOCKED** (§4.2) |
| 4 | Least-privilege tokens | `deploy/docs/TOKEN_INVENTORY.md` | Every row designed; none created yet |
| 5 | Cloudflare access policy + Zero Trust group | §5 below | **BLOCKED** (§5.1) |
| 6 | Token inventory | `deploy/docs/TOKEN_INVENTORY.md` | Written |
| 7 | Break-glass runbook | `deploy/runbooks/BREAK_GLASS.md` | Written; not yet executed |

### Risks
- **R1 — Single operator.** The owner is account holder, approver, reviewer and break-glass holder. No control here can stop the owner; controls here stop *everything else* (VGE, CI, a stolen token) and make owner actions *visible*.
- **R2 — Free-plan feature gaps.** GitHub Free has no branch protection on private repos; Cloudflare Zero Trust Free needs a card on file. Each is a decision for the owner, not a workaround for Claude.
- **R3 — Operator workstation token.** The GitHub CLI on the owner's PC holds an OAuth token with `repo` scope over **every** repo of the account (observed 2026-10-02, §6). It is outside the system path but is the broadest credential in reach of Claude Code sessions.
- **R4 — Vercel Hobby terms.** The site deploys from a personal Vercel account (`vercel[bot]` deployments, homepage `vsoftsol-website.vercel.app`). If that account is on Hobby, Vercel's terms restrict Hobby to non-commercial use, and vsoftsol.com is commercial. Plan not confirmed: **OPEN**.

### Assumptions to confirm (asked 2026-10-02; owner replied "proceed" without answering)
| # | Assumption | Status |
|---|---|---|
| A1 | Site repo is `saqibtechnn/vsoftsol-website` | **Observed, not confirmed by owner.** It is the only repo described as "vsoftsol.com marketing site" (`gh repo list`, 2026-10-02) |
| A2 | VGE repo GitHub location | **OPEN** — this repo has no git remote |
| A3 | Product repos read by VGE | **OPEN** — candidates seen in `gh repo list`: `agentic-enhancement-platform` (private), `vsoftsol-syslog-manager`, `vSoft-Baclup-Updates`, `VsoftNetwork-Monitoring`, `Updates` (public). Not assumed |
| A4 | OCI tenancy exists, home region `ca-toronto-1`, no payment method | **OPEN** |
| A5 | MFA on GitHub, OCI, Cloudflare | **OPEN** — cannot be read with the current GitHub token (§6) |
| A6 | vsoftsol.com DNS is on Cloudflare | **OPEN** |
| A7 | Social platforms in scope | **OPEN** — treated as deferred; no social credential is created in D1 |
| A8 | Vercel plan (Hobby/Pro) | **OPEN** (R4) |

### Rollback
Every D1 change is revocable: delete the GitHub ruleset (`gh api -X DELETE repos/<repo>/rulesets/<id>`), uninstall/delete the GitHub App, delete OCI IAM users/groups/policies, revoke Cloudflare tokens. Each command is in `TOKEN_INVENTORY.md`. No D1 step touches DNS or data.

---

## 2. Identity model

Principle: **humans authenticate as themselves with MFA; machines authenticate as machine identities that no human logs in as.** On a single-operator system "no personal accounts in the system path" means: no runtime component of VGE uses a credential that belongs to the owner's personal login.

| Provider | Human identity (owner) | Machine identity | Why this form |
|---|---|---|---|
| GitHub | `saqibtechnn`, MFA | **GitHub App `vge-site-bot`** (owned by `saqibtechnn`), installed on the site repo only | Apps act as themselves (`vge-site-bot[bot]`), get 1-hour installation tokens, per-repo install, per-permission scopes. A machine *user* account would be a second personal-style login with its own password and MFA to guard |
| GitHub (CI) | — | Actions `GITHUB_TOKEN` (per-job, auto-expiring) for GHCR push; cosign keyless via OIDC | No long-lived PAT exists for CI |
| OCI | Tenancy admin (owner), MFA | IAM user `vge-tofu` (API key only, no console password) in group `vge-provisioners`; IAM user `vge-backup` (customer secret key only) in group `vge-backup-writers` | Separates "can build infrastructure" (used from Codespaces only during D2) from "can write backups" (on the host forever) |
| OCI (host) | — | **Instance principal** via dynamic group `vge-prod-host` if the host needs OCI API access | No key on disk at all; preferred over `vge-backup` if WAL-G supports it in D4 |
| Cloudflare | Owner, MFA | **Account-owned API token** `vge-tofu-dns` (DNS edit on one zone, Tunnel edit) + tunnel token `vge-prod-tunnel` | Account-owned tokens are not tied to the owner's user and survive a change of user |
| Vercel | Owner | **OPEN** — project-scoped token `vge-vercel-preview-read` only if VGE needs preview status | GitHub check status on the PR may make a Vercel token unnecessary (fewer credentials) |
| Email | Owner hand-sends | none (DECISIONS #7) | Draft-only |
| LLM | — | none (DECISIONS #16) | Deferred |
| Social | — | none until A7 is answered | Deferred |

## 3. Separation rules
1. A machine identity is used by exactly one component in one environment. Staging (Codespaces) never holds a production identity (`DEPLOYMENT_PLAN.md` §1 hard rule).
2. Only the `dispatcher` container receives the GitHub App private key (DECISIONS #14). Workers and agents never do.
3. Provisioning credentials (`vge-tofu`, `vge-tofu-dns`) live only in the owner's Codespaces secrets, never on the host.
4. No credential is created "for later". If a component does not exist yet, its credential does not exist yet.

## 4. GitHub controls

### 4.1 Site repo `saqibtechnn/vsoftsol-website` (public)
Public repos on GitHub Free support rulesets. A **ruleset** is used instead of classic branch protection because it supports a bypass mode of `pull_request`: the admin may bypass the review requirement **only when merging a pull request**, never by pushing directly. That is the only way a single owner can both (a) be unable to push to `main` and (b) still merge their own changes.

Ruleset `protect-main` (`ops/github/site-main-ruleset.json`), target `~DEFAULT_BRANCH`, enforcement `active`:
| Rule | Effect |
|---|---|
| `pull_request`, 1 approving review, dismiss stale reviews, require last-push approval, thread resolution | VGE's bot PRs need the owner's approval. Owner's own PRs need the logged bypass |
| `non_fast_forward` | No force push |
| `deletion` | `main` cannot be deleted |
| `required_signatures` | Every commit on `main` must be verified. GitHub signs web merges and API commits made by Apps; the owner must configure SSH commit signing locally |
| bypass: `RepositoryRole` admin (actor_id 5), mode `pull_request` | Owner may merge their own PR without a second reviewer. Each bypass is recorded in the ruleset insights log and reviewed monthly (DECISIONS #9) |

Environment protection rules: the site deploys through Vercel's GitHub integration, not GitHub Actions environments, so there is no GitHub environment to protect. The production gate for the site is the PR approval above.

### 4.2 VGE repo — **BLOCKED**
The VGE repo has no remote (A2). If it is created **private** on GitHub Free, rulesets, branch protection and environment required-reviewers are unavailable ([GitHub plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans), retrieved 2026-10-02). Deliverable 3 cannot then be met. Options for the owner (none chosen):
- **A.** VGE repo **public**: ruleset as §4.1. Cost USD 0. Exposes control design (not secrets — those are SOPS-encrypted per DECISIONS #10). Threat-model change needed.
- **B.** GitHub Pro, USD 4/month: breaks DECISIONS #23.
- **C.** Private repo, accept the gap in writing: production stays protected by owner-signed manifests (DECISIONS #19); direct pushes to `main` are *detected* (not blocked) by a scheduled audit. This is a departure from the D1 exit gate and needs a recorded risk acceptance.

### 4.3 Signed commits
`required_signatures` on the site repo is enforced by GitHub. For this repo (VGE), no git identity is configured on this PC (owner rule); commits are made only after the owner sets identity and signing. Owner steps: `D1_ACCOUNT_SETUP.md` §4.

## 5. Cloudflare access

### 5.1 Zero Trust organisation — **BLOCKED**
Cloudflare Zero Trust Free (≤ 50 users) requires a payment method on file even at USD 0 ([Cloudflare community](https://community.cloudflare.com/t/choose-the-zero-trust-free-plan-with-no-payment-method/471877), retrieved 2026-10-02). Without it there is no Access, and DECISIONS #5 (console behind Access) fails. Options (none chosen):
- **A.** Add a card to Cloudflare only; monthly billing check added to `SIZING_AND_COST.md` §4. Charges are possible only by actively selecting a paid plan or exceeding 50 seats.
- **B.** Replace Access with another free private-access path (e.g. Tailscale): reverses DECISIONS #5, needs a D0 amendment first (CLAUDE.md §2.6).

### 5.2 Design once unblocked
- Account members: owner only, role *Super Administrator*, MFA enforced at account level (*Manage Account → Members → Enforce 2FA*).
- Zero Trust group `vge-operators`: include = emails `{owner address}`; require = identity provider GitHub (`saqibtechnn`) **and** one-time PIN fallback disabled.
- Access application `console.<domain>`: allow `vge-operators`, session 8 h, require purpose justification off, block everyone else (implicit deny).
- `hooks.<domain>`: Access bypass (webhooks are authenticated by HMAC in D8), path-limited.
- Audit: Cloudflare account audit log is on by default; Access authentication logs retained per plan.

## 6. Observed state at D1 start (2026-10-02, read-only)
```
$ gh auth status
  ✓ Logged in to github.com account saqibtechnn (keyring)
  - Token: gho_****REDACTED****
  - Token scopes: 'gist', 'read:org', 'repo'
$ gh api repos/saqibtechnn/vsoftsol-website --jq '{default_branch,visibility,homepage}'
{"default_branch":"main","homepage":"https://vsoftsol-website.vercel.app","visibility":"public"}
$ gh api repos/saqibtechnn/vsoftsol-website/branches/main/protection
{"message":"Branch not protected", ... "status":"404"}
$ gh api repos/saqibtechnn/vsoftsol-website/rulesets
[]
$ gh api repos/saqibtechnn/vsoftsol-website/collaborators --jq '.[].login'
saqibtechnn
$ gh api user --jq '{login,two_factor_authentication}'
{"login":"saqibtechnn","two_factor_authentication":null}
```
`two_factor_authentication: null` means "not visible to this token" (needs `user` scope), **not** "off". MFA must be evidenced by the owner (`D1_ACCOUNT_SETUP.md` §1).

## 7. Audit logging
| Provider | Log | Default | Action in D1 |
|---|---|---|---|
| GitHub (personal account) | Security log (`/settings/security-log`); ruleset bypass insights | On | None needed; monthly review |
| OCI | Audit service, 365-day retention | On, cannot be disabled | Confirm retention in runbook §2 |
| Cloudflare | Account audit log; Access logs | On | Review monthly once unblocked |
| Vercel | Activity log | On | OPEN (A8) |
