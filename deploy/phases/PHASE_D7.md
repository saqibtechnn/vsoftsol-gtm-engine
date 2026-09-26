# Phase D7 — Observability & Alerting

**Lead subagent:** `observability-engineer`
**Prerequisite:** D6 gate signed
**Governing belief: an untested alert is decoration.**

## Objective
You find out from the system — not from a client, and not from a spam complaint.

## Deliverables
1. Structured JSON logging with correlation IDs, shipped to the log platform, scrubbed of PII and secrets.
2. Metrics:
   - **system** — CPU, memory, disk, network
   - **application** — request rate, latency p50/p95/p99, error rate, queue depth, job duration, job failure rate
   - **business** — content generated, claims rejected, approvals pending and aging, messages queued vs sent, bounces, complaints, opt-outs, replies, pipeline movement
   - **cost** — LLM token spend per agent, per campaign, per day
3. Distributed tracing across agent workflows.
4. Dashboards per audience: operator (is anything waiting on me? is anything wrong?) and engineer (what is slow, failing or expensive?).
5. Alerts with severity and routing: queue backlog; job failure spike; approval aging beyond SLA; bounce or complaint rate above threshold; disk above 80%; backup failure; certificate expiry; cost above budget; **guardrail rejection burst** (a spike in rejected claims or blocked sends means something upstream broke).
6. External uptime monitoring; audit-log integrity monitoring.
7. `deploy/runbooks/ALERT_RESPONSE.md` — one entry per alert: what it means, what to check, what to do.

## Verification
- [ ] **Deliberately trigger every alert condition**: fill a queue, fail jobs, simulate a bounce spike, fill a disk in a test container, expire a test certificate, exceed a cost threshold, force guardrail rejections. Confirm each fires, routes correctly and contains actionable content.
- [ ] Confirm no PII or secret reaches the log platform (search for a planted marker).
- [ ] Follow one trace from an operator action through agent calls to an external API and back.
- [ ] Confirm a **silent** agent failure (job stops running, no error) would be detected.

## Exit gate
Every alert proven by deliberate triggering. Tag `deploy-v0.7.0`.
