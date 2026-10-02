# Phase D1 Verification Report

**Phase:** D1 — Accounts, Identity & Access Foundations
**Executed by:** Claude Code (main thread; `security-engineer` role performed inline, as in D0)
**Date:** 2026-10-02
**Environment(s):** none provisioned. Read-only inspection of GitHub (`saqibtechnn/vsoftsol-website`).
**Result:** **BLOCKED** — design, inventory, runbooks and verification scripts complete; no credential created, no control applied, no verification checklist item evidenced.

---

## 1. What was built
- `deploy/docs/IDENTITY_AND_ACCESS.md` — D1 plan, identity model (one machine identity per integration), GitHub/Cloudflare control design, observed starting state, audit-log matrix, two BLOCKED items with options.
- `deploy/docs/TOKEN_INVENTORY.md` — 16 rows (13 system credentials incl. sub-rows, 3 N/A by decision), each with exact scope, storage, rotation, revocation procedure; human-account table; operator-workstation credential table; empty evidence tables to be filled with real output only.
- `deploy/runbooks/BREAK_GLASS.md` — complete procedure: triggers, sealed kit K1–K7, stop-first ordering, detection via provider logs, post-use review, drill.
- `deploy/runbooks/D1_ACCOUNT_SETUP.md` — owner-executed steps for GitHub (MFA, signing, App), OCI (home region, MFA, USD 0.01 budget alert, audit, IAM users), Cloudflare (blocked), Vercel, break-glass kit.
- `ops/github/site-main-ruleset.json` — ruleset `protect-main` for the site repo.
- `deploy/scripts/d1/` — `apply_site_ruleset.sh` (idempotent, dry-run default), `verify_site_push_blocked.sh`, `verify_github_app_scope.sh`, `verify_cloudflare_token_scope.sh`, `verify_oci_scope.sh`.

## 2. What was deliberately NOT built
- **No account, token, key or IAM object created.** Claude Code may not create accounts or handle credentials; the owner executes `D1_ACCOUNT_SETUP.md`.
- **Site ruleset not applied.** It changes push rules on a live repo that deploys to production; it needs the owner's explicit confirmation in chat. The owner's "proceed" (2026-10-02) answered none of the questions asked and is not read as confirmation of this specific change.
- Anthropic key (#16), email provider key (#7), social credentials (A7): N/A by decision.
- VGE repo protection: BLOCKED (§3, D1-B1).
- Cloudflare Zero Trust: BLOCKED (§3, D1-B2).

## 3. Decisions made
| Decision | Options considered | Chosen | Rationale | Reversible? |
|---|---|---|---|---|
| GitHub machine identity | Machine user + fine-grained PAT; GitHub App | GitHub App `vge-site-bot`, site repo only | No second login to guard; 1-hour tokens; bot identity in audit trail | Yes |
| Site main protection mechanism | Classic branch protection; ruleset | Ruleset with admin bypass mode `pull_request` | Only mechanism that blocks owner direct pushes yet lets a single owner merge own PRs (logged) | Yes (DELETE ruleset) |
| GHCR auth | PAT; `GITHUB_TOKEN` | `GITHUB_TOKEN` per job | No stored credential | Yes |
| Vercel token | Project-scoped token; none | None unless needed | PR commit status may suffice; fewer credentials | Yes |
| VGE repo visibility | Public / Pro USD 4 / private + accepted gap | **OPEN (owner)** | D1-B1 | — |
| Cloudflare Zero Trust | Card on file / Tailscale (D0 amendment) | **OPEN (owner)** | D1-B2 | — |

## 4. Verification performed

### Criterion: For each token, attempt an action outside its intended scope and confirm denial
- **Result:** **NOT RUN.** No token exists yet. Scripts written and tested for fail-closed behaviour only:
```
$ for f in deploy/scripts/d1/*.sh; do bash -n "$f" && echo "syntax OK  $f"; done
syntax OK  deploy/scripts/d1/apply_site_ruleset.sh
syntax OK  deploy/scripts/d1/verify_cloudflare_token_scope.sh
syntax OK  deploy/scripts/d1/verify_github_app_scope.sh
syntax OK  deploy/scripts/d1/verify_oci_scope.sh
syntax OK  deploy/scripts/d1/verify_site_push_blocked.sh
$ bash deploy/scripts/d1/verify_github_app_scope.sh        ; echo exit=$?
ERROR: GH_APP_ID is not set
exit=1
$ bash deploy/scripts/d1/verify_cloudflare_token_scope.sh  ; echo exit=$?
ERROR: CF_API_TOKEN is not set
exit=1
$ bash deploy/scripts/d1/verify_oci_scope.sh               ; echo exit=$?
ERROR: OCI_CLI_PROFILE is not set
exit=1
```
- **Notes:** shellcheck is not installed on the owner PC; run it in Codespaces before first use.

### Criterion: Confirm a direct push to the site repo's main is blocked
- **Result:** **FAIL (current state) / NOT RUN (test).** Main is unprotected today:
```
$ gh api repos/saqibtechnn/vsoftsol-website/branches/main/protection
{"message":"Branch not protected", ... "status":"404"}
$ gh api repos/saqibtechnn/vsoftsol-website/rulesets
[]
$ bash deploy/scripts/d1/verify_site_push_blocked.sh saqibtechnn/vsoftsol-website ; echo exit=$?
ERROR: refusing to push to a live repo without --confirm
exit=1
$ bash deploy/scripts/d1/apply_site_ruleset.sh saqibtechnn/vsoftsol-website ; echo exit=$?
Repo:       saqibtechnn/vsoftsol-website (visibility: public)
Ruleset:    protect-main from .../ops/github/site-main-ruleset.json
About to:   create ruleset (POST repos/saqibtechnn/vsoftsol-website/rulesets)
Dry run. Re-run with --apply to make this change.
exit=0
```
- **Notes:** running `verify_site_push_blocked.sh ... --confirm` (which would have stopped at its "no active rules" guard before pushing) was denied by the Claude Code permission classifier as a production-deploy action. Not retried. The owner runs it after the ruleset is applied.

### Criterion: Confirm MFA cannot be bypassed on any account in the path
- **Result:** **NOT RUN.** Cannot be read with the available token:
```
$ gh api user --jq '{login,two_factor_authentication}'
{"login":"saqibtechnn","two_factor_authentication":null}
```
`null` = not visible without `user` scope. Owner evidence required (runbook §1.1, §2.2, §3.1, §5.1).

### Criterion: Every credential in the inventory has a tested revocation path
- **Result:** **NOT RUN.** Revocation procedure documented for every row; tests defined in TOKEN_INVENTORY "Revocation test record"; installation-token revocation automated in `verify_github_app_scope.sh` checks 10–11.

### Criterion: No personal account holds a role the system depends on
- **Result:** **PASS by design / not yet evidenced.** No runtime component uses a human login (TOKEN_INVENTORY §B). Exception recorded: the operator PC's `gh` OAuth token (`repo` scope over all repos, §C) is outside the system path but within reach of Claude sessions.

### Billing alert at the ceiling; audit logging enabled
- **Result:** **NOT RUN** (owner, runbook §2.3–2.4).

## 5. Adversarial / negative tests
- Scripts that could change production state carry guards, reviewed for "what if the control is missing": `verify_site_push_blocked.sh` pushes only an empty commit and only after confirming the ruleset is active; `verify_github_app_scope.sh` check 9 confirms the `pull_request` rule is active before attempting a write to `main`; `verify_oci_scope.sh` uses a read (lifecycle-policy get) instead of a bucket delete to test bucket-manage denial; Cloudflare checks are reads or invalid-value writes.
- No control is live, so no adversarial test against a real control was possible.

## 6. Defects found
| ID | Severity | Description | Status | Fix / accepted risk |
|---|---|---|---|---|
| D1-B1 | High | VGE repo: GitHub Free has no branch protection/rulesets/env reviewers on private repos; deliverable 3 unachievable for a private VGE repo | **BLOCKED — owner decision** | IDENTITY_AND_ACCESS §4.2 options A/B/C |
| D1-B2 | High | Cloudflare Zero Trust Free requires a payment method on file; DECISIONS #5 (Access) depends on it | **BLOCKED — owner decision** | §5.1 options A/B |
| D1-F1 | High | Site repo `main` unprotected today; anyone with push access (incl. operator `gh` token) can change production | Open | Apply `protect-main` on owner confirmation |
| D1-F2 | Medium | Operator `gh` token has `repo` scope on all repos | Open | Owner decision (TOKEN_INVENTORY §C) |
| D1-F3 | Medium | Site may be on Vercel Hobby (non-commercial terms) for a commercial site | OPEN (A8) | Owner confirms plan |
| D1-F4 | Low | `DECISIONS.md` text requires every row signed before D1; 18 rows still PENDING; D0 gate commit calls per-row initials optional | Open | Owner states which rule applies |

## 7. Known limitations
- Single operator: controls constrain machines and make owner actions visible; they cannot stop the owner.
- Ruleset bypass by the admin is logged, not prevented; the monthly review is the control.
- OCI Budgets on an Always-Free-only tenancy not yet confirmed to exist (runbook §2.3 stops if not).

## 8. Residual risks
| Risk | Likelihood | Impact | Mitigation | Accepted by |
|---|---|---|---|---|
| Owner is sole break-glass holder | Medium | High | Sealed kit, drill | Owner (2026-09-28), pending written sign-off |
| Unprotected site `main` until ruleset applied | Medium | High | Apply now | — not accepted |
| Broad operator token | Medium | High | Narrow after D1 | — OPEN |

## 9. Documentation produced or updated
IDENTITY_AND_ACCESS.md, TOKEN_INVENTORY.md, BREAK_GLASS.md, D1_ACCOUNT_SETUP.md — none yet followed end to end (they need the owner).

## 10. Rollback path
`git revert` the D1 commit. No external state was changed in this session.

## 11. Recommendation to the gate
**BLOCKED — do not mark PASS.** To unblock:
1. Owner decides D1-B1 (VGE repo: A public / B Pro / C private + written risk acceptance) and D1-B2 (Cloudflare: A card / B Tailscale via D0 amendment).
2. Owner confirms in chat: apply `protect-main` to `saqibtechnn/vsoftsol-website` (and that this is the site repo, A1).
3. Owner answers A2–A8 and executes `D1_ACCOUNT_SETUP.md`.
4. Scope, revocation and push tests run; real output pasted here; break-glass drill recorded.
Gate row in `DEPLOY_GATES.md` is left for the owner to edit (status suggestion: BLOCKED). No tag applied.
