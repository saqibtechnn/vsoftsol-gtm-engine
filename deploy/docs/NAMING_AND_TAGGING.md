# Naming and Tagging Conventions

Produced in Phase D0 (2026-09-27). Applies to every resource created from D1 onward. An untagged or mis-named resource is a D2 finding.

## Resource names
Pattern: `vge-<env>-<component>[-<nn>]`, lowercase, hyphens only.

| Resource | Example |
|---|---|
| Droplet | `vge-prod-host-01`, `vge-stg-host-01` |
| Managed Postgres cluster | `vge-prod-pg`, `vge-stg-pg` |
| Database / app role | database `vge`, role `vge_app` (no superuser); migration role `vge_migrator` |
| Spaces bucket | `vge-prod-artefacts`, `vge-prod-backups` |
| Off-provider backup bucket | `vge-prod-backups-offsite` |
| VPC | `vge-prod-vpc` |
| Firewall | `vge-prod-fw` |
| Cloudflare tunnel | `vge-prod-tunnel` |
| Compose project | `vge` |
| Containers | `vge-api`, `vge-worker`, `vge-scheduler`, `vge-console`, `vge-dispatcher`, `vge-egress-proxy`, `vge-redis`, `vge-proxy`, `vge-tunnel` |

`<env>` is one of `dev`, `stg`, `prod`.

## Hostnames (Cloudflare, under a zone chosen in D1)
- `console.<zone>` — operator console (Access-gated)
- `hooks.<zone>` — webhook intake (signature-verified, Access bypass on the webhook path only)
- Staging uses a `stg-` prefix: `stg-console.<zone>`.

## Mandatory tags (DigitalOcean tags / labels)
| Tag | Values |
|---|---|
| `project:vge` | always |
| `env:<dev\|stg\|prod>` | always |
| `owner:<github-handle>` | always |
| `managed-by:opentofu` | on everything OpenTofu creates |
| `data-class:<none\|internal\|pii>` | `pii` on Postgres and backup buckets |
| `cost-center:gtm` | always |

## Versioning
| Artefact | Scheme |
|---|---|
| Deployment phase gates | git tag `deploy-v0.<n>.0` (D14: `v1.0.0-prod`) |
| Application releases | SemVer `vMAJOR.MINOR.PATCH` |
| Container images | `ghcr.io/<owner>/vge-<component>:<semver>`; deployed **by digest** only; never `latest` |
| Prompts | `prompts/<agent>/<name>@v<n>`, referenced by ID |
| Migrations | Alembic revision IDs; expand/contract pairs named `<nnn>_expand_<x>` / `<nnn>_contract_<x>` |

## Secrets and config
- Environment variables: `VGE_*` for application settings; provider variables keep the provider's conventional name (`ANTHROPIC_API_KEY`).
- SOPS files: `config/sops/<env>.enc.yaml`. **Not** `secrets/` — `.gitignore` ignores `secrets/`, and git cannot re-include `*.enc.yaml` inside an ignored directory (tracked as finding F11 in THREAT_MODEL.md).
- Credentials in `TOKEN_INVENTORY.md` are named `<provider>-<env>-<purpose>`, e.g. `github-prod-site-pr`.
