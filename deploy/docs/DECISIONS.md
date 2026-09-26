# Deployment Decisions

Filled in during Phase D0. Every row needs an owner sign-off before D1 begins.
Recommended defaults are from the deployment plan; Claude Code must state agreement or disagreement with reasons.

| # | Decision | Recommended default | Chosen | Rationale | Reversal path | Signed off |
|---|---|---|---|---|---|---|
| 1 | Hosting | Single hardened VPS, 4 vCPU / 8 GB / 80 GB, CA or EU region | | | | |
| 2 | Data residency | Canada | | | | |
| 3 | Database | Managed Postgres with PITR | | | | |
| 4 | Redis | Self-hosted in Compose, persistence on | | | | |
| 5 | Console exposure | Cloudflare Tunnel + Access, zero open inbound ports | | | | |
| 6 | Outbound email domain | Dedicated subdomain, never primary vsoftsol.com | | | | |
| 7 | Email provider | Draft-only now; transactional provider at go-live | | | | |
| 8 | Container registry | GHCR | | | | |
| 9 | CI/CD | GitHub Actions with environment protection | | | | |
| 10 | Secrets | SOPS + age for config; provider store at runtime | | | | |
| 11 | IaC | OpenTofu (provision) + Ansible (configure) | | | | |
| 12 | Observability | Hosted free tier initially | | | | |
| 13 | Environments | dev / staging / production, all three | | | | |

## Open questions for the owner
- Monthly budget ceiling (infrastructure + LLM spend): ______
- Hosting region confirmation: ______
- Who holds the break-glass credentials: ______
- Who is the approver for outbound sends (may differ from the deployer): ______
