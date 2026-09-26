# Phase D11 — Resilience, Capacity & Disaster Recovery

**Lead subagents:** `release-engineer` + `data-reliability-engineer`
**Prerequisite:** D10 gate signed

## Objective
Know what breaks it, and know how you get it back.

## Deliverables
1. Load and soak testing (Locust) of API, worker pool and scheduler at **2× expected peak**. Record throughput, latency percentiles, saturation point and headroom.
2. Queue backpressure behaviour under a large campaign.
3. **Failure injection**, each with documented observed behaviour vs expected:
   - Postgres unavailable
   - Redis unavailable
   - Anthropic API rate-limited, then erroring
   - GitHub unavailable
   - Email provider failing
   - Host reboot mid-job
   - Disk full
   - Network partition
4. **Idempotency proof**: partial failure must never produce a duplicate send, duplicate publish, lost approval or corrupted audit trail. Idempotency keys and exactly-once semantics on every side-effecting operation.
5. Updated `deploy/runbooks/DISASTER_RECOVERY.md` with RTO/RPO targets.
6. **Full DR rehearsal**: rebuild the entire production environment from IaC plus backups into a clean account, timed.
7. `deploy/docs/CAPACITY.md` — concrete limits of current sizing and the trigger point for scaling up.

## Verification
- [ ] Every failure injection has a recorded observed behaviour and a pass/fail judgement.
- [ ] DR rehearsal completed and timed against target, with a written gap list.
- [ ] Replay jobs after each failure mode; confirm **no duplicate side effects**.
- [ ] Confirm the system fails closed on every dependency loss — never "send anyway".
- [ ] Capacity report states what breaks first and at what load.

## Exit gate
DR rehearsal completed with **measured** RTO/RPO. No failure mode produces a duplicate or lost outbound action. Tag `deploy-v0.11.0`.
