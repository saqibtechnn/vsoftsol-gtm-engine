# Phase D4 — Data Layer, Backup & Restore

**Lead subagent:** `data-reliability-engineer`
**Prerequisite:** D3 gate signed
**Governing belief: an untested backup is not a backup.**

## Objective
The data survives the infrastructure — proven, not assumed.

## Deliverables
1. Managed Postgres: TLS-only connections, dedicated least-privilege application role (never superuser), connection pooling, encryption at rest, private networking where available.
2. Redis: persistence enabled, password auth, bound to a private interface, not publicly reachable.
3. `deploy/docs/MIGRATION_STRATEGY.md` — zero-downtime expand/contract pattern documented step by step: additive migration → deploy → backfill → switch → contract.
4. Automated daily logical backups **plus** provider PITR. Encrypted. A second copy stored off the provider. Lifecycle and retention configured.
5. Retention and deletion jobs implementing the compliance policy: contact PII retention, audit log retention, deletion-on-request.
6. `deploy/runbooks/RESTORE.md` and `deploy/runbooks/DISASTER_RECOVERY.md`.

## Verification
- [ ] **Execute a real restore drill**: restore the latest backup to a fresh database, run the application against it, confirm integrity. Record the **RTO and RPO actually achieved** versus target.
- [ ] Run migrations up and down against a populated database.
- [ ] Prove Redis is unreachable from outside the host.
- [ ] Execute a deletion request end to end: confirm the contact is gone from primary storage, the backup policy for residual copies is documented, and the audit trail retains the fact of deletion without the PII.
- [ ] Confirm backup failure raises an alert (wire this now, verify again in D7).
- [ ] Confirm the application role cannot perform superuser operations.

## Exit gate
Documented, **measured** RTO/RPO from an executed drill. Tag `deploy-v0.4.0`.
