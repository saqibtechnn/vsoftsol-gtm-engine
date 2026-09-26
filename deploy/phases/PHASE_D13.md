# Phase D13 — Production Cutover & Controlled Go-Live

**Lead subagent:** `release-engineer` (owner present throughout)
**Prerequisite:** D12 gate signed
**Every stage in this phase requires explicit human confirmation before proceeding.**

## Objective
Go live deliberately, at low volume, with the ability to stop instantly.

## Deliverables
1. `deploy/runbooks/GO_LIVE_CHECKLIST.md` with explicit **abort criteria**.
2. Cutover window scheduled with the owner present.
3. Production deployed via the pipeline (no manual host access).
4. Production smoke suite executed.
5. **Canary sequence with hold points and review between each stage:**
   - Stage 1 — one website content PR only, **no sends**. Human review and merge.
   - Stage 2 — one social post.
   - Stage 3 — a 10-contact outbound batch, each message **individually approved**.
   - Stage 4 — a 50-contact batch.
6. Monitoring watch window with defined thresholds that trigger a halt.
7. **Emergency stop rehearsed in production before the first real send.**
8. Operator trained on the console, the approval flow and the stop procedure.
9. Hypercare schedule agreed.

## Verification
- [ ] Every canary stage reviewed against its success criteria before the next begins.
- [ ] Emergency stop executed in production, confirmed to halt everything, then cleanly resumed.
- [ ] First real content PR reviewed by a human before merge.
- [ ] First real outbound batch individually approved — no bulk approval.
- [ ] Bounce and complaint rates checked after each batch against abort thresholds.
- [ ] Cost tracked against the D0 budget throughout.

## Exit gate
Go-live checklist fully signed. Abort criteria never breached — or breached and correctly acted upon. Tag `deploy-v0.13.0`.
