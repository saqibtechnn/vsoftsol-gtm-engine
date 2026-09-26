# Phase D2 — Infrastructure as Code & Host Provisioning

**Lead subagent:** `infra-engineer`
**Prerequisite:** D1 gate signed
**Confirmation required** before any paid provisioning or DNS change.

## Objective
The host exists, is hardened, and can be recreated from nothing.

## Deliverables
1. OpenTofu modules: host, firewall, DNS records, object storage, managed Postgres. Remote state, encrypted, with locking.
2. Ansible playbooks for host hardening:
   - OS updates + unattended security upgrades
   - SSH: key-only, root login disabled, non-default port, limited users
   - fail2ban; nftables/UFW default-deny inbound
   - **Egress allowlist** — Anthropic API, GitHub, Vercel, email provider, social APIs, permitted research destinations. Everything else denied.
   - sysctl and kernel hardening, auditd, time sync, log rotation, disk and swap layout
   - Docker engine with daemon hardening: no privileged containers, userns-remap, live-restore
   - Dedicated non-root service user
3. `deploy/runbooks/HOST_REBUILD.md` — full rebuild from empty account, step by step.

## Implementation tasks
- Everything idempotent. Re-running changes nothing.
- Present `tofu plan` output and wait for confirmation before `apply` against any paid resource.
- Keep the egress allowlist in one file, commented with why each destination is needed.

## Verification
- [ ] `tofu plan` clean and idempotent on re-run.
- [ ] **Destroy and rebuild the whole host on a throwaway target**; confirm identical resulting state.
- [ ] External port scan: only the intended surface reachable (ideally nothing, with the tunnel in place).
- [ ] Lynis or equivalent benchmark scan; every finding fixed or accepted in writing with rationale.
- [ ] Attempt egress to a denied destination; confirm the block with evidence.
- [ ] SSH with password auth attempted; confirm refusal.

## Exit gate
Full rebuild demonstrated end to end with evidence. Hardening scan score and triage recorded. Tag `deploy-v0.2.0`.
