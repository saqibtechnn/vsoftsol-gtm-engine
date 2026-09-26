# Deployment Architecture

Produced in Phase D0 (2026-09-27). Amends the plan §3 topology with two components — `dispatcher` and `egress-proxy` — per DECISIONS.md #14 and #15. Status: **awaiting owner sign-off**.

## Topology

```
                              Internet
                                 │
      ┌──────────────────┬───────┴─────────┬─────────────────────┐
      │                  │                 │                     │
 vsoftsol.com       Cloudflare         Sending domain        Research targets
 (Vercel, DNS on    Zero Trust         (D12 provider,        (public web,
  Cloudflare)       Tunnel             separate domain)       robots/ToS honoured)
      ▲             ├ console. (Access/OIDC+MFA)  ▲                 ▲
      │ PR only     └ hooks.   (HMAC, replay-safe)│ send            │ via proxy only
      │                  │ outbound-only tunnel   │                 │
 ┌────┴──────────────────┴────────────────────────┴─────────────────┴─────┐
 │ VGE HOST  (DigitalOcean TOR1, s-4vcpu-8gb, zero inbound ports)          │
 │                                                                         │
 │  cloudflared ─► caddy ─► console (Next.js)                              │
 │                      └─► api (FastAPI) ◄── webhooks                     │
 │                                                                         │
 │  scheduler ─► redis (queues/locks only) ◄─ worker (agents, LLM calls)   │
 │                                              │ research fetches         │
 │                                              ▼                          │
 │                                         egress-proxy ──► public web     │
 │                                                                         │
 │  dispatcher  ◄── approved items only (reads approvals from Postgres)    │
 │   holds: email send key, site-repo write, social tokens                 │
 │                                                                         │
 │  host egress allowlist (nftables): Anthropic, GitHub, GHCR, Vercel,     │
 │  Cloudflare, email provider, social APIs, observability, DO APIs,       │
 │  OS/package mirrors. Everything else DENIED.                            │
 └──────────────────────────────┬──────────────────────────────────────────┘
                                │ TLS (sslmode=verify-full), private VPC
                   DigitalOcean Managed PostgreSQL 16 (TOR1)
                   daily backups + 7-day PITR
                                │
            ┌───────────────────┴─────────────────────┐
     DO Spaces (TOR1)                       Off-provider copy (encrypted)
     artefacts, exports, logical dumps      second location, CA region preferred (D4)
```

## Component responsibilities

| Component | What it does | May talk to | Holds credentials | When it dies |
|---|---|---|---|---|
| `cloudflared` | Outbound-only tunnel for `console.` and `hooks.` | Cloudflare edge; caddy | Tunnel token | Console and webhooks unreachable. Nothing is sent or published because of it. Providers retry webhooks. Alert (D7). |
| `caddy` | Internal TLS, security headers, request size and rate limits, routing | console, api | none | Same as tunnel. |
| `console` | Operator UI: approval queues with diffs, pipeline, ledger, audit viewer, stop button | api only | Session cookie only — **no provider tokens** | No approvals can be given. The system waits; nothing proceeds unapproved. |
| `api` | Control plane, approval recording, webhook intake (signature-verified), `/healthz` `/readyz` `/version` | Postgres, Redis | DB app role; webhook signing secrets | Approvals and webhooks stop; workers keep drafting; dispatcher sends nothing new (nothing newly approved). |
| `scheduler` | Enqueues periodic jobs (research refresh, retention, re-verification) | Redis, Postgres | DB app role | No new scheduled work. Silent-failure alert (D7). |
| `worker` | Runs agents: scanning, research, positioning, content, prospect scoring, drafting | Postgres, Redis, Anthropic API, GitHub (**read-only**), egress-proxy | Anthropic key; read-only repo token | Jobs stay queued; leases expire and retry idempotently. |
| `egress-proxy` | Only path to arbitrary web hosts. SSRF deny (private ranges, metadata IPs), protocol allowlist, redirect cap, per-domain rate limit, request logging | public web | none | Research stops (fails closed). |
| `dispatcher` | Performs every external side effect: send email, open site PR, post social. Before each: approval valid and unexpired, suppression clear, compliance checklist pass, emergency stop clear, idempotency key unused — **all read from Postgres** | Postgres, email provider, GitHub (write to site repo branches only), social APIs | **Only** holder of send, site-write and social tokens | Nothing is sent or published. Correct fail-closed state. |
| `redis` | Queues, locks, rate-limit windows, caches | internal network only | password | Work delayed; no safety state lost (DECISIONS #4). |
| Managed Postgres | System of record: approvals, claims, suppressions, contacts, audit log, idempotency keys, stop state | — | — | `/readyz` not-ready; dispatcher and workers halt. |

## Data flows (write path to the outside world)

1. The worker drafts an artefact → stored in Postgres with a `PENDING_APPROVAL` state and a claim-ledger check.
2. The operator reviews it in the console → the api records a decision (approver, timestamp, diff hash) in Postgres and the audit log.
3. The dispatcher polls for approved items → re-validates everything → performs the side effect with an idempotency key → records the result.
4. Provider webhooks (bounce, complaint, unsubscribe) → `hooks.` → api → permanent suppression in Postgres.

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
| Host → Postgres | SQL | Private VPC, TLS verify-full, least-privilege role | D4 |

## Public / private / allowlisted

- **Public:** vsoftsol.com (Vercel); the `hooks.` webhook path (authenticated).
- **Private (Access-gated):** console, api.
- **Internal only:** redis, worker, scheduler, dispatcher, egress-proxy.
- **Allowlisted egress:** the list in the diagram, maintained in one commented file (D2).

## What breaks first
To be filled from D11 capacity testing. D0 expectation: LLM API rate limits and cost ceilings bind long before host CPU or memory (see SIZING_AND_COST.md).
