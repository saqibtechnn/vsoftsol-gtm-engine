# Phase D12 — Deliverability, Compliance & Legal Readiness

**Lead subagent:** `deliverability-compliance`
**Prerequisite:** D11 gate signed
**Nothing real is sent before this phase passes.**

## Objective
Handle the part that quietly destroys outbound programs — properly, before the first real message.

## Deliverables
1. **Dedicated sending domain or subdomain** — never the primary business domain — configured with:
   - SPF
   - DKIM (2048-bit)
   - DMARC starting at `p=none` with reporting, tightening to `quarantine`/`reject` once data is clean
   - correct reverse DNS and MX
2. DMARC aggregate report monitoring.
3. `deploy/docs/WARMUP_SCHEDULE.md` — paced volume ramp with engagement thresholds and abort criteria.
4. Seed-list and inbox-placement testing across major providers.
5. Bounce, complaint and feedback-loop handling wired to a **permanent** suppression list.
6. Unsubscribe tested end to end, including one-click list-unsubscribe headers.
7. Sender identity and physical address in every template.
8. `deploy/docs/COMPLIANCE_EVIDENCE.md` — CASL / CAN-SPAM / GDPR checklist evidenced per template; lawful basis recorded per contact source.
9. Privacy policy and data-processing documentation published on the website.
10. Retention and deletion jobs verified running in production.

## Verification
- [ ] Authenticated test send: SPF, DKIM and DMARC all **pass** at major providers.
- [ ] Inbox placement tested across at least three mailbox providers; results recorded.
- [ ] Trigger a hard bounce, a soft bounce, a complaint and an unsubscribe; confirm each lands on the suppression list **permanently**.
- [ ] Confirm a suppressed address **cannot be re-added** by a later prospecting run.
- [ ] Confirm the compliance checklist blocks a template missing a physical address or with a broken unsubscribe.
- [ ] Confirm no purchased or scraped source can enter the prospect pipeline.

## Exit gate
Authentication passing, suppression proven irreversible, compliance checks enforced in code. Tag `deploy-v0.12.0`.
