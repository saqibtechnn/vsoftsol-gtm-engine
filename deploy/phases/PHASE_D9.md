# Phase D9 — CI/CD Pipeline

**Lead subagent:** `release-engineer`
**Prerequisite:** D8 gate signed

## Objective
Deployment becomes boring, repeatable and reviewable. No human touches a production host.

## Deliverables
GitHub Actions pipeline with these stages:
1. Lint (ruff, black --check, ESLint), type-check (mypy --strict, tsc --noEmit)
2. Unit tests with coverage thresholds
3. Integration tests against ephemeral Postgres and Redis service containers
4. Security scans: bandit, pip-audit, npm audit, Trivy, gitleaks
5. Build and **sign** images; publish to GHCR
6. Auto-deploy to **staging** on merge to main
7. Staging smoke + e2e suites
8. **Manual approval gate** for production (GitHub environment protection, required reviewer)
9. Production deploy
10. Production smoke tests with **auto-rollback on failure**
11. Deployment notification and a record appended to `deploy/verification/DEPLOY_LOG.md`: version, digest, approver, changes, result

Plus: concurrency controls preventing overlapping deploys; artefact retention policy.

## Verification
- [ ] Push a change; watch the full path to staging succeed.
- [ ] Confirm production requires a human approval and that the approver is logged.
- [ ] Introduce a deliberately failing test; confirm the pipeline blocks.
- [ ] Introduce a deliberately failing production smoke test; confirm **automatic rollback**.
- [ ] Trigger two concurrent deploys; confirm they cannot race.
- [ ] Confirm no secret is printed in any pipeline log.

## Exit gate
A complete change deployed to production through the pipeline with **no manual host access at any point**. Tag `deploy-v0.9.0`.
