# RACI

Produced in Phase D0 (2026-09-27). R = Responsible (does it), A = Accountable (signs off), C = Consulted, I = Informed.

## Roles
| Role | Who | Notes |
|---|---|---|
| **Owner** | VSoftSol owner (GitHub `saqibtechnn`) | Accountable for everything; signs every gate |
| **Builder** | Claude Code (main thread + specialist subagents) | Never signs a gate; never approves its own outbound |
| **Independent verifier** | `qa-verifier` subagent | Must not be the same session that built the phase where practical |
| **Outbound approver** | **OPEN** — a named person (may be the owner) | Approves every send and publish in the console |
| **Code reviewer** | **OPEN** — second person, or owner via logged admin bypass (DECISIONS #9) | |
| **Break-glass holder** | **OPEN** — ideally someone other than the owner | Holds the sealed emergency credentials |
| **On-call (2am)** | Owner | Single operator: no rotation. Alert routing to the owner's phone (D7) |

## Matrix
| Activity | Owner | Builder | Verifier | Outbound approver | Break-glass holder |
|---|---|---|---|---|---|
| Deployment decisions (D0) | A | R | C | I | I |
| Account and token creation (D1) | A/R (console clicks where unavoidable) | R (IaC, runbooks) | C | I | C |
| Infrastructure provisioning (D2) | A (approves `tofu plan` + spend) | R | C | – | I |
| Images, data, secrets, release mechanics (D3–D6) | A | R | C | – | I |
| Observability, security, CI/CD (D7–D9) | A | R | C | – | I |
| Staging rehearsal (D10) | A | R | R | R (exercises approvals) | I |
| Resilience and DR (D11) | A | R | C | – | C |
| Deliverability and compliance (D12) | A | R | C | C | – |
| Go-live (D13) | A (present throughout) | R | C | R | I |
| Final readiness audit (D14) | A | C | R | C | C |
| Phase gate sign-off | **A/R** | never | recommends | – | – |
| Approving a send or publish | I | never | – | **A/R** | – |
| Merging a site PR | A/R | never | – | C | – |
| Production deploy approval (GitHub environment) | **A/R** | never | – | – | – |
| Emergency stop | R (anyone may pull it) | R (on instruction) | – | R | R |
| Restarting after an emergency stop | **A/R** | C | – | C | – |
| Rollback | A | R (via pipeline) | – | – | – |
| Secret rotation | A | R | – | – | C |
| Break-glass use | A (reviews afterwards) | – | – | – | R |
| Incident response | A/R | R | C | C | C |
| Budget changes | A/R | C | – | – | – |

## Escalation
Alert → owner (phone). If the owner is unreachable and outbound is misbehaving: **anyone with console or host access pulls the emergency stop first, asks second** (`deploy/runbooks/EMERGENCY_STOP.md`, written in D6).

## Single-operator limitations (accepted pending owner decision)
- No separation of duties between deployer, reviewer and approver unless the OPEN roles are filled.
- No on-call rotation; alert fatigue and absence are real risks. Mitigation: conservative send windows, low volume, and a stop that works without the console.
