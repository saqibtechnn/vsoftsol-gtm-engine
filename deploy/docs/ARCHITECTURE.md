# Deployment Architecture

> Completed in Phase D0. The diagram below is the starting proposal from the plan — confirm, amend or replace it with the agreed design.

## Topology

```
                       Internet
                          │
        ┌─────────────────┼──────────────────┐
        │                 │                  │
   vsoftsol.com      Cloudflare          Sending domain
   (Vercel site)      Zero Trust          (transactional
        │            Tunnel + Access        provider)
        │                 │                  │
        │            ┌────┴─────┐            │
        └──PR/API────┤  VGE HOST ├───SMTP/API┘
                     │  (VPS)    │
                     ├───────────┤
                     │ proxy     │  TLS, security headers, rate limit
                     │ api       │  FastAPI control plane
                     │ worker    │  RQ workers
                     │ scheduler │  periodic jobs
                     │ console   │  Next.js operator UI
                     │ redis     │  queues, rate limits, locks
                     └─────┬─────┘
                           │ TLS
                    Managed Postgres
                   (backups + PITR)
                           │
                    Object storage
               (artefacts, exports, backups)
```

## Trust boundaries
| Boundary | What crosses it | Control |
|---|---|---|
| Internet → host | Nothing inbound | Zero open ports; tunnel only |
| Host → internet | Allowlisted destinations only | Egress allowlist (D2) |
| Fetched web content → agents | Data only, never instructions | Injection defences (D8) |
| Agent → send credential | Only via approval component | Credential isolation (D8) |
| Staging → real recipients | Nothing | Send-guard allowlist (D5, D10) |

## Component responsibilities
<Fill in: what each container does, what it may talk to, what happens when it dies.>

## What breaks first
<From D11 capacity testing. Fill in after that phase and keep current.>
