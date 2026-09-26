# Phase D0 Verification Report

**Phase:** D0 — Deployment Architecture & Readiness Baseline
**Executed by:** Claude Code (main thread; `deployment-architect` role performed inline)
**Date:** 2026-09-27
**Environment(s):** none — documentation phase, nothing provisioned
**Result:** **PASS WITH CONDITIONS — awaiting owner sign-off and owner inputs**

---

## 1. What was built
- `deploy/docs/DECISIONS.md` — all 13 plan §2 decisions answered with choice, rationale and reversal path; 5 further decisions (#14–#18) surfaced; open questions listed.
- `deploy/docs/ARCHITECTURE.md` — final topology, component responsibilities (including failure behaviour), data flows, trust boundaries, public/private/allowlisted surfaces.
- `deploy/docs/ENVIRONMENTS.md` — dev/staging/production matrix, forbidden actions per environment, promotion path.
- `deploy/docs/SIZING_AND_COST.md` — workload assumptions, container memory budget, cost per environment as single figures, ceiling and alerts, LLM cost per campaign.
- `deploy/docs/THREAT_MODEL.md` — 10 assets, 7 actors, entry points, 19 threats each with mitigation, phase and residual risk; 15 scaffold findings tracked (F1–F15).
- `deploy/docs/NAMING_AND_TAGGING.md` — resource names, hostnames, mandatory tags, versioning, secret file locations.
- `deploy/docs/RACI.md` — roles, activity matrix, escalation, single-operator limitations.
- Repository initialised (commit `b92775d`) with `.gitattributes` pinning LF endings.

## 2. What was deliberately NOT built
- Nothing provisioned, purchased or configured at any provider (D0 rule).
- Scaffold defects F1–F15 were **not** fixed; each is assigned to its owning phase in THREAT_MODEL.md §5.
- The go-live email provider is not chosen; that happens in D12 against provider terms (DECISIONS #7).
- `ops/scripts/preflight.sh` reports FAIL (Docker not installed). D0 produces documents only and needs no Docker, so D0 proceeded. **Docker Desktop + WSL2 must be installed before D2.** Recorded here as a condition, not waived.

## 3. Decisions made
See `deploy/docs/DECISIONS.md`. Summary of where Claude Code departed from the plan's defaults:

| Decision | Plan default | Chosen | Rationale | Reversible? |
|---|---|---|---|---|
| #1 Hosting | Single VPS (Hetzner/DO/Vultr) | DigitalOcean TOR1 | Hetzner has no Canadian region; DO has droplet, managed Postgres (TOR1 confirmed on provider availability page) and storage in one region | Yes |
| #2 Residency | Canada | Canada at rest; US processors disclosed | LLM and SaaS processing happens outside Canada; honesty required in the privacy policy | Yes |
| #4 Redis | Self-hosted, queue state reconstructable | Self-hosted; safety state in Postgres only | Otherwise losing Redis could cause duplicate or unapproved sends | Yes |
| #6 Sending domain | Dedicated subdomain | Separate domain recommended | Full reputation isolation | Yes |
| #7 Email provider | Transactional provider at go-live | Provider whose terms permit cold outreach | Postmark prohibits unsolicited email | Yes |
| #9 CI/CD | GitHub Actions | + GitHub Team plan | Environment protection on private repos requires Team (pricing page, 2026-09-27) | Yes |
| #10 Secrets | Provider secret store at runtime | tmpfs decrypt at boot | DigitalOcean has no general secret manager | Yes |
| #14 | — | `dispatcher` credential isolation | Makes the approval gate unbypassable by architecture (D8) | Yes, with risk acceptance |
| #15 | — | Research egress proxy | Reconciles "egress allowlist" with "research arbitrary sites" | Yes |

## 4. Verification performed

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
- **Result:** Answer and rationale **PASS**. Owner sign-off **NOT YET** — all 18 decisions show PENDING or OPEN.
- **Notes:** Condition C1 below.

### Criterion: Architecture reviewed against plan §1 and §3; no principle contradicted
- **Method:** Manual review, principle by principle (no command can check this):

| Plan §1 principle | Where satisfied | Contradiction? |
|---|---|---|
| Reproducible over convenient | ARCHITECTURE (host holds no data), DECISIONS #13 ephemeral staging | None |
| Right-sized, no Kubernetes | Single host + Compose; scale trigger in SIZING_AND_COST §2 | None |
| Private by default | Zero inbound ports; console behind Access; only `hooks.` public, authenticated | None — `hooks.` is the plan's permitted "webhook endpoints" surface |
| Fail closed | Component table: every failure leads to "nothing sent" | None |
| Every outbound action reversible or gated; stop works without console | Dispatcher gate; T17; RACI escalation | None |
| Data minimisation as infrastructure | PII only in Postgres; retention jobs D4; tags `data-class:pii` | None |
| Plan §3 topology | Retained; adds `dispatcher` and `egress-proxy` | Additive amendment, recorded as DECISIONS #14–#15 |

- **Result:** PASS

### Criterion: Cost model produces concrete monthly figures per environment with a stated ceiling
- **Command run:** independent recomputation of every figure in SIZING_AND_COST.md
```
awk 'BEGIN{ split("48.00 30.45 5.00 1.00 1.25 4.00 10.00",a," "); ... }'
```
- **Output:**
```
prod_infra=99.70 campaign=53.25 (in=6.50 out=0.83) prod_llm=243.00 prod_total=342.70
staging_infra=3.22 staging_total=56.47 all_envs=409.17 llm/infra_all=2.98 llm/infra_prod=2.44 sonnet_campaign=21.30
```
- **Result:** PASS — every figure matches the document. Ceiling proposed at USD 450, alert at USD 360; **the ceiling itself awaits owner confirmation** (C1).
- **Notes:** The droplet price (USD 48) is the DigitalOcean Basic list price for this tier. The fetched pricing page confirmed the USD 24 2 vCPU/4 GB plan in the same tier but did not render the 4 vCPU/8 GB row, so it is re-confirmed in D2's `tofu plan` review (C4).

### Criterion: Every threat has at least one concrete mitigation mapped to a specific later phase
- **Command(s) run:**
```
awk -F'|' '/^\| T[0-9]+ \|/ { n++; if ($6 !~ /D[0-9]+/) { print "UNMAPPED "$2; bad++ } } END { print n" threats, "bad+0" unmapped" }' deploy/docs/THREAT_MODEL.md
for k in "web content" "email reply" "Over-permissioned" "Unapproved send" "exfiltration" "supply-chain" "Credential compromise" "Operator error"; do grep -qi "$k" deploy/docs/THREAT_MODEL.md && echo "  [x] $k" || echo "  [ ] MISSING $k"; done
```
- **Output:**
```
19 threats, 0 unmapped
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
- **Command run:** keyword traceability over `deploy/phases/*.md` for the plan §1/§3/§4 requirements
- **Output:**
```
  egress allowlist                   D2
  Tunnel                             D6
  emergency stop                     D14 D6
  PITR                               D4
  send-guard                         D10 D5
  SBOM                               D3
  cosign                             D3
  prompt-injection|hostile instructions D14 D8
  suppression                        D10 D12 D3
  DMARC                              D12
  restore drill                      D4
  retention                          D4 D9
  rate limit                         D8
  MFA                                D1 D8
  manual approval|Manual approval    D9
  rollback                           D14 D6 D9
  canary|Canary                      D13
  warm-up                            UNMAPPED
  idempotency|Idempotency            D11
  fail closed|fails closed           D11 D14 D6
  data minimi|PII                    D14 D4 D7
  staging                            D0 D10 D5 D9
  log scrubbing|Log scrubbing        D5
```
Follow-up on the one UNMAPPED hit:
```
grep -niE "warm.?up|volume ramp" deploy/phases/*.md
deploy/phases/PHASE_D12.md:17:3. `deploy/docs/WARMUP_SCHEDULE.md` — paced volume ramp with engagement thresholds and abort criteria.
```
- **Result:** PASS — warm-up is mapped to D12; the miss was a wording difference. The "suppression → D3" hit is a false positive (scanner suppressions), and suppression is still correctly mapped to D10/D12.
- **Notes:** Keyword traceability is shallow by nature. D14 performs the full requirement-by-requirement audit.

### Supporting check: no placeholder text left in D0 deliverables
```
DECISIONS.md: 0
ARCHITECTURE.md: 0
ENVIRONMENTS.md: 0
SIZING_AND_COST.md: 0
THREAT_MODEL.md: 0
NAMING_AND_TAGGING.md: 0
RACI.md: 0
```
PASS.

## 5. Adversarial / negative tests
D0 introduces no runtime controls. The adversarial work in this phase was a review of the plan and scaffold for bad foundations; it produced findings F1–F15 (THREAT_MODEL §5), of which F3 (stop is slow), F4 (history not scanned), F10 (no evidence source) and F13 (provider terms) would each have caused a real failure later.

## 6. Defects found
| ID | Severity | Description | Status | Fix / accepted risk |
|---|---|---|---|---|
| F1–F15 | High ×6 (F1–F4, F10, F13), Medium ×5, Low ×4 | Scaffold and plan defects (THREAT_MODEL §5) | Open | Assigned to owning phases; none block D0 |

## 7. Known limitations
- Provider prices change; they are dated 2026-09-27 and re-confirmed at D2.
- The LLM cost is an estimate from token budgets, not a measurement. D7 measures real spend; D10 records a real campaign cost.
- The Postmark finding comes from a secondary source; D12 re-reads the provider's primary terms.

## 8. Residual risks
| Risk | Likelihood | Impact | Mitigation | Accepted by |
|---|---|---|---|---|
| LLM estimate low by 2× | Medium | Medium | Daily and per-campaign hard stops; D7 cost alerts | Owner (pending) |
| Single operator: no separation of duties | High | Medium | OPEN roles in RACI; logged admin bypass | Owner (pending) |
| Application not ready for D3–D5 | High | Medium | DECISIONS #17 | Owner (pending) |

## 9. Documentation produced or updated
Seven D0 docs listed in §1. No runbook belongs to D0.

## 10. Rollback path
Documentation only: `git revert` the D0 commit. Each decision carries its own reversal path in DECISIONS.md.

## 11. Recommendation to the gate
**PASS WITH CONDITIONS.** Conditions:
- **C1** — Owner signs off every row in DECISIONS.md and confirms the budget ceiling (USD 450 proposed).
- **C2** — Owner fills the OPEN inputs that D1 depends on: outbound approver, break-glass holder, second reviewer (yes/no), site repo `owner/repo`, product repo locations.
- **C3** — Owner decides DECISIONS #17 (D3–D5 sequencing) and #16 (default model).
- **C4** — Droplet price re-confirmed in the D2 `tofu plan` review.
- **C5** — Docker Desktop + WSL2 installed before D2; preflight shows no FAIL.

Sending domain and physical address (also OPEN) are needed by D12, not D1.
