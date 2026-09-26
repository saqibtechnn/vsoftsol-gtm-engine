# Phase D10 — Staging Rehearsal & Integration Validation

**Lead subagent:** `qa-verifier` (with support from all others)
**Prerequisite:** D9 gate signed

## Objective
Prove every external integration in a full dress rehearsal — before anything real happens.

## Deliverables
1. Staging populated with **synthetic** products, synthetic prospects, and a sandbox site repository.
2. GitHub integration validated against the sandbox repo: branch, MDX write, PR creation, checks, preview link capture.
3. Vercel preview validated.
4. Email gateway in sandbox mode with the **send-guard allowlist active**.
5. Social adapters in dry-run mode.
6. Anthropic API usage with per-campaign cost tracking.
7. **A complete campaign executed end to end in staging**: portfolio scan → market research → positioning → content generation → site PR → approval → social queue → prospect list → outbound draft → approval → simulated send → reply handling → pipeline update → report.
8. `deploy/verification/STAGING_REHEARSAL.md` with the full narrative, timings and cost.

## Verification
- [ ] The end-to-end campaign completes with **every human gate exercised**, not bypassed.
- [ ] Attempt to send from staging to a non-allowlisted real address; confirm a hard block.
- [ ] Confirm a staging PR can never target the production site repo's `main`.
- [ ] Confirm the suppression list blocks a suppressed test contact.
- [ ] Confirm an unverified claim blocks publication mid-campaign, with a clear operator-facing reason.
- [ ] Confirm no production credential is present anywhere in staging.
- [ ] Record full-campaign cost and duration.

## Exit gate
Rehearsal report shows every gate functioning and **zero cross-environment leakage**. Tag `deploy-v0.10.0`.
