# Deployment Architecture

Produced in Phase D0 (2026-09-27). Amends the plan §3 topology with two components — `dispatcher` and `egress-proxy` — per DECISIONS.md #14 and #15. Revised 2026-09-28: hosting on OCI Always Free with **Postgres self-hosted on the host** (DECISIONS #1, #3) and production releases gated by an **owner signature verified on the host** (#19). Status: **awaiting owner sign-off**.

## Topology

```
                               Internet
                                  │
      ┌───────────────────┬───────┴──────────┬──────────────────────┐
      │                   │                  │                      │
 vsoftsol.com        Cloudflare          Owner's mailbox        Research targets
 (Vercel, DNS on     Zero Trust          (hand-sends approved   (public web,
  Cloudflare)        Tunnel               drafts; subdomain      robots/ToS honoured)
      ▲              ├ console. (Access/   of vsoftsol.com)            ▲
      │ PR only      │   OIDC + MFA)             ▲                     │ via proxy only
      │              └ hooks. (HMAC; reserved    │ owner copies        │ (only once an
      │                 for future providers)    │ approved drafts     │  LLM exists)
 ┌────┴───────────────────┴──────────────────────┴─────────────────────┴───┐
 │ VGE HOST  OCI Always Free A1 (arm64), ca-toronto-1, 2 OCPU / 12 GB       │
 │           zero inbound ports                                             │
 │                                                                          │
 │  cloudflared ─► caddy ─► console (Next.js)                               │
 │                      └─► api (FastAPI) ◄── owner-logged bounces/replies  │
 │                                                                          │
 │  scheduler ─► redis (queues/locks only) ◄── worker (no LLM until #16)    │
 │                                               │ research fetches         │
 │                                               ▼                          │
 │                                          egress-proxy ──► public web     │
 │                                                                          │
 │  dispatcher ◄── approved items only (reads approvals from Postgres)      │
 │    holds: site-repo write token, social tokens (sole holder)             │
 │    email: renders approved drafts for hand-sending (draft-only, #7)      │
 │                                                                          │
 │  postgres 16 (self-hosted) ─► wal-g: continuous WAL archive + daily dump │
 │  deploy-agent: deploys ONLY owner-signed release manifests (#19)         │
 │                                                                          │
 │  host egress allowlist (nftables): GitHub, GHCR, Vercel, Cloudflare,     │
 │  social APIs, observability, OCI APIs, backup store, OS mirrors,         │
 │  LLM provider (added only when #16 is decided). All else DENIED.         │
 └───────────────────────────────┬──────────────────────────────────────────┘
                                 │ WAL + dumps, client-side encrypted
                OCI Object Storage, ca-toronto-1 (Always Free, 20 GB)
                7-day PITR window, daily dumps, OpenTofu state
                                 │
                   Off-provider encrypted copy (free tier; location set in D4)

 Dev + staging: GitHub Codespaces (separate credentials, own tunnel) — #13, #22
```

## Component responsibilities

| Component | What it does | May talk to | Holds credentials | When it dies |
|---|---|---|---|---|
| `cloudflared` | Outbound-only tunnel for `console.` and `hooks.` | Cloudflare edge; caddy | Tunnel token | Console and webhooks unreachable. Nothing is sent or published because of it. Providers retry webhooks. Alert (D7). |
| `caddy` | Internal TLS, security headers, request size and rate limits, routing | console, api | none | Same as tunnel. |
| `console` | Operator UI: approval queues with diffs, pipeline, ledger, audit viewer, stop button | api only | Session cookie only — **no provider tokens** | No approvals can be given. The system waits; nothing proceeds unapproved. |
| `api` | Control plane, approval recording, webhook intake (signature-verified), `/healthz` `/readyz` `/version` | Postgres, Redis | DB app role; webhook signing secrets | Approvals and webhooks stop; workers keep drafting; dispatcher sends nothing new (nothing newly approved). |
| `scheduler` | Enqueues periodic jobs (research refresh, retention, re-verification) | Redis, Postgres | DB app role | No new scheduled work. Silent-failure alert (D7). |
| `worker` | Runs agents: scanning, research, positioning, content, prospect scoring, drafting | Postgres, Redis, LLM provider (none until DECISIONS #16), GitHub (**read-only**), egress-proxy | LLM key (once chosen); read-only repo token | Jobs stay queued; leases expire and retry idempotently. |
| `egress-proxy` | Only path to arbitrary web hosts. SSRF deny (private ranges, metadata IPs), protocol allowlist, redirect cap, per-domain rate limit, request logging | public web | none | Research stops (fails closed). |
| `dispatcher` | Performs every external side effect: open site PR, post social, and release approved email drafts for hand-sending (draft-only, DECISIONS #7). Before each: approval valid and unexpired, suppression clear, compliance checklist pass, emergency stop clear, idempotency key unused — **all read from Postgres** | Postgres, GitHub (write to site repo branches only), social APIs | **Only** holder of site-write and social tokens (and of an email-send key if one is ever added) | Nothing is sent or published. Correct fail-closed state. |
| `redis` | Queues, locks, rate-limit windows, caches | internal network only | password | Work delayed; no safety state lost (DECISIONS #4). |
| `postgres` (self-hosted) | System of record: approvals, claims, suppressions, contacts, audit log, idempotency keys, stop state. Bound to the internal Compose network only | internal network only | superuser password (never used by the app); `vge_app` role | `/readyz` not-ready; dispatcher and workers halt (fail closed). Host loss → restore from WAL archive; RPO = archive lag (target ≤ 5 min) |
| `wal-g` sidecar | Continuous WAL archiving + daily base backup and logical dump to OCI Object Storage, client-side encrypted; replicates to the off-provider copy | postgres, OCI Object Storage, off-provider store | storage keys (write-only where the provider allows) | Archive lag grows; **backup-failure alert** (D4/D7). Nothing unsafe happens, but RPO worsens until fixed |
| `deploy-agent` | Polls for release manifests; verifies the **owner signature** plus cosign image signatures; performs the health-gated rollout | GHCR, GitHub (read), Docker socket | read-only registry token; owner **public** key only | No deploys happen. Running release unaffected |

## Data flows (write path to the outside world)

1. The worker drafts an artefact → stored in Postgres with a `PENDING_APPROVAL` state and a claim-ledger check.
2. The operator reviews it in the console → the api records a decision (approver, timestamp, diff hash) in Postgres and the audit log.
3. The dispatcher polls for approved items → re-validates everything → performs the side effect with an idempotency key → records the result.
4. Bounces, complaints, unsubscribes and replies: with draft-only sending (DECISIONS #7) the **owner logs each one in the console** → api → permanent suppression in Postgres. The `hooks.` webhook path stays reserved for a future sending provider.

No path exists from 1 to 3 that skips 2. The worker cannot perform 3 because it lacks the credentials.

## Trust boundaries

| Boundary | What crosses it | Control | Phase |
|---|---|---|---|
| Internet → host | Nothing inbound | Zero open ports; tunnel only | D2, D6 |
| Internet → `hooks.` | Provider webhooks | HMAC signature, timestamp replay window, rate limit, Access bypass scoped to that path | D8 |
| Operator → console | Human decisions | Cloudflare Access OIDC + MFA; RBAC in app | D1, D8 |
| Host → internet | Allowlisted destinations only | nftables egress allowlist | D2 |
| Worker → public web | Research fetches | egress-proxy SSRF and policy controls | D8 |
| Fetched content / repo content / email replies → agents | **Data only, never instructions** | Content delimiting, per-agent tool allow-lists, no credentials in the agent tier | D8 |
| Worker → side effects | Nothing directly | Credential isolation in `dispatcher` | D8 |
| Staging → real recipients | Nothing | Send-guard allowlist in the dispatcher | D5, D10 |
| App containers → Postgres | SQL | Internal Compose network only, never published; least-privilege `vge_app` role; TLS inside the host network | D4 |
| CI → production | Nothing directly | Host deploys only owner-signed release manifests (DECISIONS #19) | D9 |

## Public / private / allowlisted

- **Public:** vsoftsol.com (Vercel); the `hooks.` webhook path (authenticated).
- **Private (Access-gated):** console, api.
- **Internal only:** redis, worker, scheduler, dispatcher, egress-proxy.
- **Allowlisted egress:** the list in the diagram, maintained in one commented file (D2).

## What breaks first
To be filled from D11 capacity testing. D0 expectation: LLM API rate limits and cost ceilings bind long before host CPU or memory (see SIZING_AND_COST.md).
