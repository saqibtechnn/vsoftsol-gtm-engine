# Phase D0 Verification Report

**Phase:** D0 — Deployment Architecture & Readiness Baseline
**Executed by:** Claude Code (main thread; `deployment-architect` role performed inline)
**Date:** 2026-09-27, revised 2026-09-28 (owner chose near-free hosting)
**Environment(s):** none — documentation phase, nothing provisioned
**Result:** **PASS WITH CONDITIONS — awaiting owner sign-off and owner inputs**

---

## 1. What was built
- `deploy/docs/DECISIONS.md` — all 13 plan §2 decisions answered with choice, rationale and reversal path; 8 further decisions (#14–#21); open questions. Revised for the owner's free-hosting choice; the cost-driven departures from the plan are marked **COST-DRIVEN**.
- `deploy/docs/ARCHITECTURE.md` — topology on OCI Always Free (arm64, Toronto) with self-hosted Postgres + WAL-G, `dispatcher` credential isolation, research `egress-proxy`, and a `deploy-agent` accepting only owner-signed releases; component responsibilities with failure behaviour; data flows; trust boundaries.
- `deploy/docs/ENVIRONMENTS.md` — dev/staging/production matrix, forbidden actions, promotion path via owner-signed release.
- `deploy/docs/SIZING_AND_COST.md` — workload assumptions, 12 GB memory budget, cost per environment as single figures, ceiling and alerts.
- `deploy/docs/THREAT_MODEL.md` — 10 assets, 7 actors, 22 threats each with mitigation, phase and residual risk; 15 scaffold findings (F1–F15).
- `deploy/docs/NAMING_AND_TAGGING.md` — OCI resource names, hostnames, mandatory tags (incl. `free-tier`), versioning, secret file locations.
- `deploy/docs/RACI.md` — roles (owner is approver and break-glass holder; no second reviewer), activity matrix, escalation.
- Repository initialised (commit `b92775d`) with `.gitattributes` pinning LF endings.

## 2. What was deliberately NOT built
- Nothing provisioned, purchased or configured at any provider (D0 rule). **No Oracle account was created.** The home-region choice at sign-up is irreversible, and account creation is a D1 owner action.
- Scaffold defects F1–F15 were not fixed; each is assigned to its owning phase.
- `ops/compose/compose.prod.yaml` was not changed to add `postgres`, `wal-g` and `deploy-agent`. That is D4/D6/D9 work, and the design is recorded here.
- Go-live email provider not chosen (D12).
- `ops/scripts/preflight.sh` reports FAIL (Docker not installed). D0 needs no Docker. **Docker Desktop + WSL2 must be installed before D2** (condition C5).

## 3. Decisions made
See `deploy/docs/DECISIONS.md`. Departures from the plan's defaults:

| Decision | Plan default | Chosen | Rationale | Reversible? |
|---|---|---|---|---|
| #1 Hosting | Single VPS 4 vCPU / 8 GB | OCI Always Free A1 2 OCPU / 12 GB, `ca-toronto-1` | Owner's cost choice; Toronto region confirmed on Oracle's regions page | Yes (rebuild + restore) |
| #2 Residency | Canada | Canada at rest; US processors disclosed | Honesty in the privacy policy | Yes |
| #3 Database | Managed Postgres | **Self-hosted** + WAL-G 7-day PITR + off-provider copy | Owner's cost choice; **contrary to the plan's advice**; D4 must prove restore from WAL | Yes |
| #4 Redis | Queue state reconstructable | Safety state in Postgres only | Prevents duplicate or unapproved sends on Redis loss | Yes |
| #6 Sending domain | Subdomain | Separate domain recommended | Reputation isolation | Yes |
| #7 Email provider | Transactional provider | Provider whose terms permit cold outreach | Postmark prohibits unsolicited email | Yes |
| #9 CI/CD | GitHub environment protection | GitHub Free + owner-signed release (#19) | Environment protection on private repos needs a paid plan | Yes |
| #13 Staging | Permanent | Ephemeral, paid hourly (USD 2.28/month) | Production uses the whole free A1 allowance | Yes |
| #14, #15, #19–#21 | — | dispatcher, egress proxy, owner-signed releases, arm64, reclaim guard | Architecture needed for D8 and the free tier | Yes |

## 4. Verification performed
All commands below were re-run on 2026-09-28 against the revised documents.

### Criterion: Every decision in plan §2 has a recorded answer, rationale and owner sign-off
- **Command(s) run:**
```
awk -F'|' '/^\| (1[0-3]|[1-9]) \|/ { n++; for(i=5;i<=7;i++){ g=$i; gsub(/ /,"",g); if(g==""){print "EMPTY cell in row "$2; bad++} } } END { print n" rows checked, "bad+0" empty cells" }' deploy/docs/DECISIONS.md
grep -cE '\| (PENDING|\*\*OPEN\*\*)' deploy/docs/DECISIONS.md
```
- **Output:**
```
13 rows checked, 0 empty cells
18
```
- **Result:** Answer and rationale **PASS**. Owner sign-off **NOT YET**: 18 of 21 decisions show PENDING or OPEN (#9, #16 and #17 carry owner answers from 2026-09-28).

### Criterion: Architecture reviewed against plan §1 and §3; no principle contradicted
Manual review, principle by principle:

| Plan §1 principle | Where satisfied | Contradiction? |
|---|---|---|
| Reproducible over convenient | Host rebuildable from IaC; data restorable from off-host WAL archive; ephemeral staging rebuilds routinely | None |
| Right-sized, no Kubernetes | Single host + Compose | None |
| Private by default | Zero inbound ports (OCI NSG); console behind Access; only authenticated `hooks.` public | None |
| Fail closed | Every component failure leads to "nothing sent" | None |
| Every outbound action gated; stop works without console | Dispatcher; T17 | None |
| Data minimisation as infrastructure | PII only in Postgres; retention jobs D4 | None |
| Plan §2 decision 3 guidance ("self-hosting a database you must never lose is a false economy") | — | **Deliberate, owner-driven departure.** Recorded as COST-DRIVEN in DECISIONS #3 with compensating controls (WAL-G PITR, off-provider copy, restore drill in D4) and threat T21 |
| Plan §3 topology | Retained; adds dispatcher, egress-proxy, wal-g, deploy-agent; Postgres moves onto the host | Amendment, recorded |

- **Result:** PASS WITH CONDITION. The one departure from plan advice is explicit, owner-driven and needs owner sign-off (C1).

### Criterion: Cost model produces concrete monthly figures per environment with a stated ceiling
- **Command run:** independent recomputation (awk) of every figure in SIZING_AND_COST.md
- **Output:**
```
prod_infra=11.25 campaign=53.25 prod_llm=243.00 prod_total=254.25
staging_infra=2.28 staging_total=55.53 dev=10.00 all_envs=319.78 llm_share=95.8% saving_vs_draft=89.39
memory_limits_MB=8576 of 12288
```
Cross-check that the documents quote the same figures:
```
grep -ohE "(319\.78|254\.25|55\.53|13\.53|306\.25|11\.25|27\.74|8576 MB)" deploy/docs/SIZING_AND_COST.md deploy/docs/DECISIONS.md | sort | uniq -c
      2 11.25
      1 13.53
      1 254.25
      2 27.74
      1 306.25
      2 319.78
      1 55.53
      1 8576 MB
```
- **Result:** PASS. Ceiling proposed at USD 350, alert at USD 280, awaiting owner confirmation (C1).
- **Notes:** Two arithmetic slips in the first revision (a paid-instance figure and the total) were caught by this recomputation and corrected before this report. Sources disagree on the free A1 allowance: third-party pages cite 4 OCPU / 24 GB, Oracle's current documentation says 2 OCPU / 12 GB. The model uses Oracle's figure.

### Criterion: Every threat has at least one concrete mitigation mapped to a specific later phase
- **Command(s) run:** as in the first revision (awk over T-rows; keyword presence check)
- **Output:**
```
22 threats, 0 unmapped
  [x] web content
  [x] email reply
  [x] Over-permissioned
  [x] Unapproved send
  [x] exfiltration
  [x] supply-chain
  [x] Credential compromise
  [x] Operator error
```
- **Result:** PASS

### Criterion: No unmapped requirement — every plan requirement appears in some phase's deliverables
- **Command run:** keyword traceability over `deploy/phases/*.md` (2026-09-27; phase files unchanged since)
- **Output:** 22 of 23 requirement keywords mapped directly. "warm-up" initially UNMAPPED; the follow-up grep found it in `PHASE_D12.md:17` (`WARMUP_SCHEDULE.md — paced volume ramp`).
- **Result:** PASS. Note: D4's deliverables assume *managed* Postgres ("Managed Postgres: TLS-only…"). With DECISIONS #3, D4 must also cover **self-hosted** Postgres hardening and **WAL-archive restore**. Carried as condition C6.

### Supporting checks
```
== placeholder text in D0 deliverables: 0 in each of the 7 files
== stale provider references (DigitalOcean|TOR1|droplet|Spaces|GitHub Team plan) in ARCHITECTURE/ENVIRONMENTS/NAMING/THREAT_MODEL/RACI: none
```
PASS. (DECISIONS.md and SIZING_AND_COST.md mention DigitalOcean and GitHub Team deliberately, as the costed alternatives and reversal paths.)

## 5. Adversarial / negative tests
D0 introduces no runtime controls. The adversarial work was a review for bad foundations: findings F1–F15, plus three new threats (T20–T22) that the free-tier design creates.

## 6. Defects found
| ID | Severity | Description | Status | Fix / accepted risk |
|---|---|---|---|---|
| F1–F15 | High ×6, Medium ×5, Low ×4 | Scaffold and plan defects (THREAT_MODEL §5) | Open | Assigned to owning phases |
| D0-1 | Low | Arithmetic slips in the first free-tier revision | Fixed | Caught by the V4 recomputation |

## 7. Known limitations
- Provider limits and prices are dated 2026-09-27/28. Oracle can change Always Free terms; D2 re-confirms.
- The LLM cost is an estimate, not a measurement (D7 measures; D10 records a real campaign).
- The Postmark finding comes from a secondary source; D12 re-reads the primary terms.
- Oracle's docs do not state whether Pay As You Go tenancies are exempt from idle reclamation; treated as **not exempt**.

## 8. Residual risks
| Risk | Likelihood | Impact | Mitigation | Accepted by |
|---|---|---|---|---|
| Free A1 capacity unavailable in Toronto at build or rebuild | Medium | Medium | Retry; paid A1 fallback (USD 27.74/month) | Owner (pending) |
| Idle reclamation of the free instance | Low | High | Memory stays above threshold under normal load; D7 alert; rebuild + restore runbook | Owner (pending) |
| Self-hosted DB: backups fail silently | Medium | Critical | Backup-failure alert, weekly `verify-backup.sh`, D4 drill | Owner (pending) |
| LLM estimate low by 2× | Medium | Medium | Daily and per-campaign hard stops | Owner (pending) |
| Single operator: no separation of duties; owner holds break-glass | High | Medium | Logged admin bypass; sealed offline key copy | Owner (pending) |

## 9. Documentation produced or updated
Seven D0 docs listed in §1. No runbook belongs to D0.

## 10. Rollback path
Documentation only: `git revert` the D0 commits. Each decision carries its own reversal path. Returning to the paid design means restoring the 2026-09-27 versions (commit `b27e241`).

## 11. Recommendation to the gate
**PASS WITH CONDITIONS:**
- **C1** — Owner signs off DECISIONS.md, **explicitly accepting the COST-DRIVEN rows #1, #3, #9, #13 and #21**, and confirms the budget ceiling (USD 350 proposed).
- **C2** — Owner supplies D1 inputs: site repo `owner/repo`, product repo locations. When creating the Oracle account, the owner **must choose Toronto (`ca-toronto-1`) as home region**, and must upgrade to Pay As You Go for staging.
- **C3** — Satisfied 2026-09-28: Opus 5 throughout; pause after D2.
- **C4** — Provider limits and prices re-confirmed in the D2 `tofu plan` review.
- **C5** — Docker Desktop + WSL2 installed before D2; preflight shows no FAIL.
- **C6** — D4's phase file is read as covering self-hosted Postgres hardening and WAL-archive restore (DECISIONS #3). The owner may prefer to amend `PHASE_D4.md` wording at the D4 start.

Sending domain and physical address (still OPEN) are needed by D12, not D1.
