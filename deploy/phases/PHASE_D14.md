# Phase D14 — Final Production Readiness Verification

**Lead subagent:** `qa-verifier`
**Prerequisite:** D13 gate signed

## Stance
Perform this as an **independent software quality verification expert** reviewing this deployment for the first time, with no investment in the work already done. **Assume defects exist.** Your job is to find them, not to confirm the deployment is fine. A finding you suppress to make a gate pass is a failure of your function.

## The eleven-point protocol

### 1. Traceability audit
Map every requirement in `deploy/plan/DEPLOYMENT_PLAN.md` (Sections 1, 3, 4 and every phase deliverable) to the artefact implementing it and the evidence verifying it. **Anything unmapped is a defect.**

### 2. Clean-room rebuild
From an **empty provider account and a fresh clone**, rebuild the entire production environment using **only the written runbooks** — no tribal knowledge, no memory of having built it. Every gap, error, missing step or assumed context in the documentation is a defect with a severity.

### 3. Full regression
Application test suite plus all deployment verification checks, re-run against the live production configuration.

### 4. End-to-end business verification
Run three complete scenarios under production-equivalent conditions:
- a successful campaign;
- a campaign where compliance **correctly blocks** outbound;
- a campaign where a claim **fails verification mid-flight**.

Confirm correct behaviour, correct alerting and a complete audit trail in all three.

### 5. Guardrail assurance (adversarial)
Deliberately attempt to defeat **every** control. Each must fail closed. Document each attempt, method and result **individually**:
- publish an unverified claim
- push directly to the site repo's `main`
- send without approval
- contact a suppressed address
- exceed a frequency cap
- inject hostile instructions via fetched web content
- inject hostile instructions via an inbound email reply
- exfiltrate data to a non-allowlisted destination
- escalate privilege between console roles
- read a secret from a running container
- bypass the emergency stop

### 6. Security verification
Authenticated and unauthenticated scanning; TLS and header configuration; token scope audit against `TOKEN_INVENTORY.md`; dependency and image CVE review; log review for leaked PII or secrets; audit-log completeness and tamper-evidence.

### 7. Resilience re-verification
Spot-check failure injections; confirm the DR runbook is still accurate after every change since D11.

### 8. Observability verification
Confirm every alert still fires, every dashboard reflects reality, and no monitoring gap exists on any critical path. Confirm a **silent** agent failure would be detected.

### 9. Operational readiness
Review every runbook by **executing it**. Confirm the operator can perform approval, stop, rollback, restore and rotation unaided. Confirm cost monitoring and budget alarms work.

### 10. Operator safety and usability
Walk the console as a non-technical operator. Confirm destructive or irreversible actions are clearly marked, confirmable and reversible where possible. **Any path where an operator can cause an unintended real send or publish in fewer than two deliberate steps is a High defect.**

### 11. Defect log
Write `deploy/verification/FINAL_PRODUCTION_READINESS_REPORT.md`. Every finding: ID, severity (Critical/High/Medium/Low), area, reproduction steps, evidence, impact, root cause, fix or written risk acceptance.

## Release gate
- **Zero Critical and zero High defects open.**
- Every Medium either fixed or explicitly accepted in writing by the owner, with rationale and a review date.
- Produce a signed **Production Readiness Statement** covering: what was verified; what was **not** verified and why; known limitations; residual risks; measured RTO/RPO; capacity limits and the scale-up trigger; operational contacts.
- Tag `v1.0.0-prod`.
