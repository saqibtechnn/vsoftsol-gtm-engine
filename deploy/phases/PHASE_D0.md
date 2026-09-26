# Phase D0 — Deployment Architecture & Readiness Baseline

**Lead subagent:** `deployment-architect`
**Prerequisite:** none — this is the first phase
**Nothing is provisioned in this phase.** Decide and document before spending money or creating attack surface.

## Objective
Decide, document and bound the deployment before anything exists.

## Deliverables
1. `deploy/docs/DECISIONS.md` — every decision in Section 2 of the plan answered, with rationale and a reversal path. Flag any where you disagree with the recommended default.
2. `deploy/docs/ARCHITECTURE.md` — final topology diagram and component responsibilities; data flows; trust boundaries; what is public, what is private, what is allowlisted.
3. `deploy/docs/ENVIRONMENTS.md` — dev / staging / production matrix: purpose, data, integrations, who deploys, what is forbidden in each.
4. `deploy/docs/SIZING_AND_COST.md` — resource sizing with the workload assumptions behind each number; monthly cost per environment as a **number**, not a range; ceiling and alert threshold; LLM spend estimate per campaign.
5. `deploy/docs/THREAT_MODEL.md` — assets, actors, entry points, and threats. Must cover the agentic-specific set: prompt injection via researched web content and inbound replies; over-permissioned tokens; unapproved send or publish; exfiltration via egress; dependency supply chain; credential compromise; operator error. Each threat maps to a mitigation and the phase that implements it.
6. `deploy/docs/NAMING_AND_TAGGING.md` — resource naming, tagging and versioning conventions.
7. `deploy/docs/RACI.md` — who builds, who reviews, who approves, who is called at 2am.

## Implementation tasks
- Read `deploy/plan/DEPLOYMENT_PLAN.md` and `deploy/plan/BUILD_PROMPT.md` in full first.
- Base sizing on the real workload: bursty agent runs, LLM-bound rather than CPU-bound, small data volume, one operator, spiky queue depth during campaigns.
- Model cost including LLM API spend, which will likely exceed infrastructure cost. Say so plainly if it does.
- For each threat, state the mitigation **and** what residual risk remains after it.

## Verification
- [ ] Every decision in plan Section 2 has a recorded answer, rationale and owner sign-off.
- [ ] Architecture reviewed against plan Sections 1 and 3; no principle contradicted.
- [ ] Cost model produces concrete monthly figures per environment with a stated ceiling.
- [ ] Every threat has at least one concrete mitigation mapped to a specific later phase.
- [ ] No unmapped requirement: every plan requirement appears in some phase's deliverables.

## Exit gate
Owner sign-off recorded in `deploy/verification/DEPLOY_GATES.md`. Tag `deploy-v0.0.0`.
