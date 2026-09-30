# Phase D0 Verification Report

**Phase:** D0 — Deployment Architecture & Readiness Baseline
**Executed by:** Claude Code (main thread; `deployment-architect` role performed inline)
**Date:** 2026-09-27; revised 2026-09-28 (near-free hosting) and 2026-09-30 (USD 0 ceiling)
**Environment(s):** none — documentation phase, nothing provisioned
**Result:** **PASS WITH CONDITIONS — awaiting the owner's written sign-off**

---

## 1. What was built
- `deploy/docs/DECISIONS.md` — all 13 plan §2 decisions answered with choice, rationale and reversal path, plus decisions #14–#23. Departures driven by the owner's budget are marked **COST-DRIVEN**.
- `deploy/docs/ARCHITECTURE.md` — USD 0 topology: OCI Always Free A1 (arm64, Toronto) with self-hosted Postgres + WAL-G; `dispatcher` as sole holder of publish credentials; research `egress-proxy`; `deploy-agent` accepting only owner-signed releases; draft-only email with owner-logged bounces/replies; dev and staging in Codespaces.
- `deploy/docs/ENVIRONMENTS.md`, `SIZING_AND_COST.md` (USD 0.00 in every environment), `THREAT_MODEL.md` (25 threats, 15 scaffold findings), `NAMING_AND_TAGGING.md`, `RACI.md`.
- Repository initialised (commit `b92775d`) with `.gitattributes` pinning LF endings.

## 2. What was deliberately NOT built
- Nothing provisioned or purchased. No provider account was created.
- **No LLM provider chosen** (DECISIONS #16, deferred by the owner). The system has no AI until that decision is made.
- Scaffold defects F1–F15 not fixed; each is assigned to its owning phase.
- `ops/compose/compose.prod.yaml` not yet changed to add `postgres`, `wal-g` and `deploy-agent` (D4/D6/D9).

## 3. Decisions made — revision history
| Date | Owner input | Effect |
|---|---|---|
| 2026-09-28 | Opus 5 throughout; pause after D2; owner is outbound approver; no second reviewer; owner holds break-glass | #9, #17, RACI |
| 2026-09-28 | "proceed with free option" | OCI Always Free hosting, self-hosted Postgres, owner-signed releases (#1, #3, #9, #19–#21) |
| 2026-09-30 | D0: "Approve, different ceiling"; ceiling: "i need free" | USD 0 ceiling (#23) |
| 2026-09-30 | No Claude plan; "Yes, go fully free"; AI route "A. Defer"; "Yes, Codespaces" | vsoftsol.com subdomain (#6), permanent draft-only (#7), Codespaces dev+staging (#13, #22), LLM deferred (#16) |

Measured input to these decisions: the owner's PC is a **1 vCPU / 12 GB VM with no GPU** (read via `Win32_ComputerSystem`/`Win32_Processor`/`Win32_VideoController`, 2026-09-30), which rules out local LLM inference and makes local Docker/WSL2 impractical.

## 4. Verification performed (re-run 2026-09-30 against the final documents)

### Criterion: Every decision in plan §2 has a recorded answer, rationale and owner sign-off
```
== V1
13 rows checked, 0 empty cells
== V1b: decisions by sign-off state
owner-answered=5 pending=18 open=0
```
- **Result:** Answers and rationale **PASS**. **Written owner sign-off NOT YET recorded.** The owner approved D0 in chat on 2026-09-30, and Claude Code must not write the sign-off on the owner's behalf. See §11.

### Criterion: Architecture reviewed against plan §1 and §3; no principle contradicted
| Plan principle | Status |
|---|---|
| Reproducible over convenient | Host rebuildable from IaC; data restorable from off-host WAL archive |
| Right-sized, no Kubernetes | Single host + Compose |
| Private by default | Zero inbound ports; console behind Access |
| Fail closed | Every component failure leads to "nothing sent/published" |
| Every outbound action gated; stop without console | Dispatcher + approvals; hand-sending adds a further human step |
| Data minimisation | PII only in Postgres; retention jobs D4 |
| Plan §2.3 "self-hosting a database… is a false economy" | **Deliberate owner-driven departure** (#3), with compensating controls and threat T21 |
| Plan §1 mission (agentic system) | **Materially reduced:** no LLM until #16; no automated sending (#7). Recorded plainly in SIZING_AND_COST §3 |

- **Result:** PASS WITH CONDITION. The departures are explicit and owner-driven.

### Criterion: Cost model produces concrete monthly figures per environment with a stated ceiling
```
== V4: cost table sums to zero
8 line items, sum=0.00
== V4b: memory
8576 MB of 12288
```
- **Result:** PASS. Ceiling USD 0; enforcement mechanisms listed in SIZING_AND_COST §4 (no payment method on GitHub, Always-Free-only OCI tenancy, USD 0.01 budget alert).
- **Sources:** Oracle Always Free limits (docs.oracle.com, 2026-09-28); OCI regions incl. `ca-toronto-1` (2026-09-28); GitHub Codespaces free quota and block-not-bill behaviour (docs.github.com, 2026-09-30).

### Criterion: Every threat has at least one concrete mitigation mapped to a specific later phase
```
== V3
25 threats, 0 unmapped
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

### Criterion: No unmapped requirement
Keyword traceability over `deploy/phases/*.md` (2026-09-27; phase files unchanged): 23 of 23 requirement keywords mapped after the warm-up follow-up (`PHASE_D12.md:17`).
- **Result:** PASS, with scope notes carried as conditions C6 and C7 below. Phase files still assume managed Postgres (D4) and a sending provider with webhooks (D10, D12).

### Supporting checks
```
== V2: placeholder text: 0 in each of the 7 D0 files
== V2b: stale references (Anthropic key, WSL2 control node, paid staging, USD 350): none
```
PASS.

## 5. Adversarial / negative tests
D0 introduces no runtime controls. Bad-foundation review produced F1–F15 and threats T20–T25 from the free design. **T23 (missed manual suppression) is the weakest control in the USD 0 design.** It depends on the owner logging every unsubscribe and bounce by hand.

## 6. Defects found
| ID | Severity | Description | Status |
|---|---|---|---|
| F1–F15 | High ×6, Medium ×5, Low ×4 | Scaffold and plan defects (THREAT_MODEL §5) | Open, assigned to phases |
| D0-1 | Low | Arithmetic slips in the 2026-09-28 revision | Fixed (caught by recomputation) |
| D0-2 | Medium | A `sed` edit misplaced the "holds: credentials" line under `deploy-agent` in the architecture diagram, misstating which component holds send/publish tokens | Fixed 2026-09-30 (diagram rewritten) |

## 7. Known limitations
- The USD 0 system has **no AI and no automated sending**. It is the approval, suppression, publishing and stop platform, waiting for DECISIONS #16.
- Free-tier terms can change without notice; monthly billing review is the control.
- The Codespaces allowance is read conservatively as ≈60 h/month.

## 8. Residual risks
| Risk | Likelihood | Impact | Mitigation | Accepted by |
|---|---|---|---|---|
| Missed manual suppression (T23) | High at volume | High (legal) | One-step logging, 48 h reply gate, weekly reconciliation, low volume | Owner — pending written sign-off |
| Idle reclamation of the free host (#21) — more likely with no AI load | Medium | High | Memory above threshold; D7 alert; rebuild + restore | Owner — pending |
| Self-hosted DB backups fail silently (T21) | Medium | Critical | Alert, weekly verify, D4 drill | Owner — pending |
| Codespaces quota blocks an urgent rebuild (T24) | Low | Medium | Documented no-Codespaces path | Owner — pending |

## 9. Documentation produced or updated
Seven D0 docs listed in §1.

## 10. Rollback path
`git revert` the D0 commits. Paid design: commit `b27e241`; near-free + Opus 5: commit `fce0a3a`.

## 11. Recommendation to the gate
**PASS WITH CONDITIONS.** The owner approved D0 in chat on 2026-09-30 ("Approve, different ceiling"; ceiling "i need free"). **The written sign-off must be entered by the owner** in `DEPLOY_GATES.md` (Owner sign-off column) and `DECISIONS.md` (Signed off column). Claude Code will then apply tag `deploy-v0.0.0`.

Conditions:
- **C2** — Before D1: site repo `owner/repo` and product repo locations; the Oracle account is created with home region **Toronto (`ca-toronto-1`)** and **no payment method**; the GitHub account has **no payment method**.
- **C4** — Provider limits re-confirmed in D2.
- **C5** — Codespaces used as the tooling machine (replaces "Docker Desktop + WSL2").
- **C6** — D4 covers self-hosted Postgres hardening and WAL-archive restore (DECISIONS #3).
- **C7** — D10 and D12 verify the **manual** bounce/unsubscribe/reply logging path instead of provider webhooks (DECISIONS #7, T23).
- **C8** — Before BUILD phase 2 (first LLM use), DECISIONS #16 is decided and this cost model re-run.
