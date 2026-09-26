# Phase D6 — Application Deployment & Release Mechanics

**Lead subagent:** `release-engineer`
**Prerequisite:** D5 gate signed

## Objective
The system runs, upgrades and rolls back without drama.

## Deliverables
1. `ops/compose/compose.prod.yaml`: resource limits, restart policies, log drivers, healthchecks, dependency ordering, digest-pinned images.
2. Reverse proxy (Caddy or Traefik) with automatic TLS, HSTS, CSP and security headers.
3. Cloudflare Tunnel connecting console and API — **no open inbound ports**.
4. Graceful shutdown: in-flight jobs drained, queue leases released, SIGTERM handled with a documented grace period.
5. Health-gated rolling deploy script; one-command rollback to the previous release.
6. `/healthz` (liveness), `/readyz` (dependency-aware readiness) and `/version` endpoints.
7. **Emergency stop** implemented as a control that works from both the console **and** the host CLI, independent of console availability.
8. `deploy/runbooks/DEPLOY.md`, `deploy/runbooks/ROLLBACK.md`, `deploy/runbooks/EMERGENCY_STOP.md`.

## Verification
- [ ] Deploy, then upgrade to a new version **with traffic in flight**: zero dropped requests, zero lost jobs. Evidence both.
- [ ] Roll back; confirm the previous version is fully restored including schema compatibility.
- [ ] Kill each container in turn; confirm correct recovery.
- [ ] Take Postgres down, then Redis; confirm `/readyz` reports not-ready and the system **fails closed** rather than proceeding.
- [ ] Trigger emergency stop with the console deliberately offline; confirm all queues halt.
- [ ] Confirm TLS configuration and security headers score well on an external check.

## Exit gate
Upgrade and rollback both demonstrated under load with evidence. Tag `deploy-v0.6.0`.
