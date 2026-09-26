# Deployment Phase Gates

One row per phase. A phase is not started until the previous row reads PASS.
Sign-off is by the owner, not by Claude Code.

| Phase | Title | Status | Verified by | Owner sign-off | Date | Tag | Notes |
|---|---|---|---|---|---|---|---|
| D0 | Architecture & Readiness Baseline | NOT STARTED | | | | deploy-v0.0.0 | |
| D1 | Accounts, Identity & Access | NOT STARTED | | | | deploy-v0.1.0 | |
| D2 | IaC & Host Provisioning | NOT STARTED | | | | deploy-v0.2.0 | |
| D3 | Container & Supply Chain | NOT STARTED | | | | deploy-v0.3.0 | |
| D4 | Data, Backup & Restore | NOT STARTED | | | | deploy-v0.4.0 | |
| D5 | Secrets & Configuration | NOT STARTED | | | | deploy-v0.5.0 | |
| D6 | Deployment & Release Mechanics | NOT STARTED | | | | deploy-v0.6.0 | |
| D7 | Observability & Alerting | NOT STARTED | | | | deploy-v0.7.0 | |
| D8 | Security & Agentic-Risk Controls | NOT STARTED | | | | deploy-v0.8.0 | |
| D9 | CI/CD Pipeline | NOT STARTED | | | | deploy-v0.9.0 | |
| D10 | Staging Rehearsal | NOT STARTED | | | | deploy-v0.10.0 | |
| D11 | Resilience, Capacity & DR | NOT STARTED | | | | deploy-v0.11.0 | |
| D12 | Deliverability & Compliance | NOT STARTED | | | | deploy-v0.12.0 | |
| D13 | Cutover & Go-Live | NOT STARTED | | | | deploy-v0.13.0 | |
| D14 | Final Production Readiness | NOT STARTED | | | | v1.0.0-prod | |

Status values: NOT STARTED / IN PROGRESS / BLOCKED / FAILED / PASS WITH CONDITIONS / PASS
