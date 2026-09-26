# Environments

Produced in Phase D0 (2026-09-27). Machine-readable form: `config/environments.yaml`.

**Hard rule:** production credentials never exist in dev or staging. Each environment has its own SOPS file encrypted to its own age recipients; the staging age key cannot decrypt production.

| | dev | staging | production |
|---|---|---|---|
| **Purpose** | Local development and unit/integration tests | Full dress rehearsal of every integration | Live operation |
| **Where** | Owner workstation (Docker Desktop + WSL2) | Ephemeral DigitalOcean TOR1 droplet + smallest managed Postgres, created by OpenTofu per rehearsal and destroyed afterwards | DigitalOcean TOR1 `s-4vcpu-8gb` + managed Postgres 2 GB |
| **Data** | Synthetic fixtures only | Synthetic products and prospects; real schema. **No real personal data.** | Real data |
| **Anthropic** | Separate dev key, low spend limit | Separate staging key, per-rehearsal spend limit | Production key, daily hard ceiling |
| **GitHub** | Contract fakes | Sandbox site repo only | vsoftsol.com site repo; PRs only |
| **Vercel** | Fake | Preview deployments of the sandbox repo | Preview links on production-repo PRs |
| **Email** | `draft_only`, send-guard on | Sandbox provider mode, **send-guard allowlist enforced by the dispatcher** | Live provider (from D12), send-guard off, approval required |
| **Social** | Dry-run | Dry-run | Live, approval required |
| **Who deploys** | Developer, any time | CI on merge to `main` | CI with manual approval only (GitHub environment protection) |
| **Access** | Local | Cloudflare Access, owner only | Cloudflare Access + MFA, RBAC |
| **Monitoring** | Local logs | Grafana Cloud (staging labels) | Grafana Cloud + external uptime + alert routing |
| **Backups** | None | None (ephemeral by design) | PITR 7 days + daily encrypted logical dump + off-provider copy |

## Forbidden in each environment

| dev | staging | production |
|---|---|---|
| Real contacts | Production credentials of any kind | Manual host deploys or hot-fixes |
| Production or staging credentials | Sending outside the allowlist | Bulk approval of a first batch |
| Real sends or publishing | PRs targeting the production site repo | Sending without a recorded approver |
| | Real personal data | `REQUIRE_HUMAN_APPROVAL=false` or `GITHUB_ALLOW_DIRECT_PUSH=true` |
| | | Disabling the suppression or compliance check |

## Promotion path
`feature branch → PR (CI quality gates) → main → staging (auto) → staging smoke/e2e → manual approval → production → production smoke → auto-rollback on failure`.

Images are promoted **by digest**; the same signed digest that passed staging is the one deployed to production.
