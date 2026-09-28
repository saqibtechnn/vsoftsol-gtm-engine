# Environments

Produced in Phase D0 (2026-09-27). Machine-readable form: `config/environments.yaml`.

**Hard rule:** production credentials never exist in dev or staging. Each environment has its own SOPS file encrypted to its own age recipients; the staging age key cannot decrypt production.

| | dev | staging | production |
|---|---|---|---|
| **Purpose** | Local development and unit/integration tests | Full dress rehearsal of every integration | Live operation |
| **Where** | Owner workstation (Docker Desktop + WSL2) | Ephemeral paid OCI A1 instance (2 OCPU / 12 GB, `ca-toronto-1`) with Postgres in Compose, created by OpenTofu per rehearsal and destroyed afterwards | OCI Always Free A1 (2 OCPU / 12 GB, arm64, `ca-toronto-1`); Postgres self-hosted in Compose |
| **Data** | Synthetic fixtures only | Synthetic products and prospects; real schema. **No real personal data.** | Real data |
| **Anthropic** | Separate dev key, low spend limit | Separate staging key, per-rehearsal spend limit | Production key, daily hard ceiling |
| **GitHub** | Contract fakes | Sandbox site repo only | vsoftsol.com site repo; PRs only |
| **Vercel** | Fake | Preview deployments of the sandbox repo | Preview links on production-repo PRs |
| **Email** | `draft_only`, send-guard on | Sandbox provider mode, **send-guard allowlist enforced by the dispatcher** | Live provider (from D12), send-guard off, approval required |
| **Social** | Dry-run | Dry-run | Live, approval required |
| **Who deploys** | Developer, any time | CI on merge to `main` | Host deploy-agent, **only** for owner-signed release manifests (DECISIONS #19) |
| **Access** | Local | Cloudflare Access, owner only | Cloudflare Access + MFA, RBAC |
| **Monitoring** | Local logs | Grafana Cloud (staging labels) | Grafana Cloud + external uptime + alert routing |
| **Backups** | None | None (ephemeral by design) | WAL-G continuous archive (7-day PITR) + daily encrypted dump to OCI Object Storage + off-provider copy |

## Forbidden in each environment

| dev | staging | production |
|---|---|---|
| Real contacts | Production credentials of any kind | Manual host deploys or hot-fixes |
| Production or staging credentials | Sending outside the allowlist | Bulk approval of a first batch |
| Real sends or publishing | PRs targeting the production site repo | Sending without a recorded approver |
| | Real personal data | `REQUIRE_HUMAN_APPROVAL=false` or `GITHUB_ALLOW_DIRECT_PUSH=true` |
| | | Disabling the suppression or compliance check |

## Promotion path
`feature branch → PR (CI quality gates) → main → staging (auto) → staging smoke/e2e → owner signs release manifest → host deploy-agent verifies signature → production → production smoke → auto-rollback on failure`.

Images are promoted **by digest**; the same signed digest that passed staging is the one deployed to production.
