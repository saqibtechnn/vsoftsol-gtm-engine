# Sizing and Cost

Produced in Phase D0 (2026-09-27). All figures USD per month (DECISIONS #18). Prices retrieved 2026-09-27 from provider pages unless marked; D2 re-confirms every price in the `tofu plan` review before anything is bought.

## 1. Workload assumptions
| Assumption | Value | Why it matters |
|---|---|---|
| Operators | 1 | No concurrency on approvals; console load negligible |
| Campaigns | 4 per month (one per week), one product each | Drives LLM spend |
| Marketable products | 1 today (`config-backup`), growing | Portfolio scans scale per product |
| Prospects per campaign | 50 accounts, one contact each | Drives research and drafting tokens |
| Outbound volume | Capped by `compliance.yaml`: 10 in the first batch, then warm-up schedule (D12) | Host load is trivial; the constraint is deliverability, not compute |
| Worker concurrency | 4 concurrent jobs | Jobs are LLM-bound: mostly waiting on network, not using CPU |
| Peak queue depth | ~500 jobs during a prospecting run | Redis memory under 50 MB |
| Data volume, year 1 | Postgres under 5 GB (≈10k contacts, ≈1M audit events) | 2 GB DB plan storage is sufficient |

## 2. Resource sizing

### Production host — DigitalOcean `s-4vcpu-8gb` (4 vCPU, 8 GB, 160 GB SSD), TOR1
Memory budget (Compose `limits`):

| Container | Memory limit |
|---|---|
| worker | 2048 MB |
| api | 1536 MB |
| console | 1024 MB |
| scheduler | 512 MB |
| redis | 512 MB |
| dispatcher | 256 MB |
| egress-proxy, caddy, cloudflared | 128 MB each |
| **Total limits** | **6272 MB** of 8192 MB, leaving ≈1.9 GB for the OS and page cache |

CPU is not the constraint. Agents spend most wall-clock time awaiting the Anthropic API. Disk: ≈5 GB images + rotated logs; 160 GB leaves room for local dump staging.

**Scale-up trigger (initial, to be replaced by D11 measurements):** sustained memory above 85% or worker queue wait p95 over 10 minutes → move to `s-8vcpu-16gb` (a resize, not a re-architecture).

### Production database — Managed PostgreSQL 16, 2 GB single node, TOR1
Chosen over 1 GB because the combined connection pools (api 7, worker 7, scheduler 2, dispatcher 3 ≈ 19, plus migration and admin) need headroom. The provider's per-plan connection limit is confirmed in D4. Standby node not purchased (DECISIONS #3).

### Staging — ephemeral
`s-2vcpu-4gb` droplet + 1 GB Postgres, created per rehearsal, billed hourly. Assumed usage: **60 hours/month**.

## 3. Monthly cost per environment

### Production — infrastructure
| Item | Basis | USD/month |
|---|---|---|
| Droplet `s-4vcpu-8gb` | DigitalOcean Basic list price (same tier as the $24 2 vCPU/4 GB plan shown on the pricing page; exact figure re-confirmed at D2) | 48.00 |
| Managed PostgreSQL 2 GB | DigitalOcean pricing page | 30.45 |
| Spaces object storage | DigitalOcean base plan (250 GB) | 5.00 |
| Off-provider encrypted backup copy | ≈20 GB at commodity object-storage rates; budget line | 1.00 |
| Sending domain | ≈USD 15/year | 1.25 |
| GitHub Team, 1 seat | GitHub pricing page | 4.00 |
| Email provider / mailbox on sending domain | Reserved from D12; USD 0 until then | 10.00 |
| Cloudflare Tunnel + Access (≤50 users), Grafana Cloud free, external uptime free tier | free tiers | 0.00 |
| **Production infrastructure** | | **99.70** |

### Production — LLM (Anthropic API, `claude-opus-5` at USD 5 input / 25 output per million tokens)
Per-campaign token estimate, **including agent-loop overhead** (context re-sent across tool-use turns):

| Stage | Input MTok | Output MTok |
|---|---|---|
| Portfolio scan (1 product) | 1.00 | 0.08 |
| Claim audit | 0.40 | 0.04 |
| Market research | 1.20 | 0.12 |
| Competitive analysis + positioning | 0.60 | 0.06 |
| Content (≈10 assets) | 0.80 | 0.20 |
| Social (≈14 posts) | 0.20 | 0.05 |
| Prospecting (50 accounts) | 1.20 | 0.10 |
| Outreach drafts (50 × 3-step sequence) | 0.80 | 0.15 |
| Reply triage + campaign report | 0.30 | 0.03 |
| **Total per campaign** | **6.50** | **0.83** |

Per campaign: 6.50 × 5 + 0.83 × 25 = 32.50 + 20.75 = **USD 53.25** (uncached — deliberately conservative; prompt caching is expected to lower this, and D7 measures it).

| Item | USD/month |
|---|---|
| 4 campaigns × 53.25 | 213.00 |
| Daily operations (claim re-verification, reply triage, retention summaries) ≈ USD 1/day × 30 | 30.00 |
| **Production LLM** | **243.00** |

### Totals
| Environment | Infrastructure | LLM | **Total USD/month** |
|---|---|---|---|
| Production | 99.70 | 243.00 | **342.70** |
| Staging (60 h ephemeral: 60 × (24.00 + 15.15)/730 = 3.22; one rehearsal campaign 53.25) | 3.22 | 53.25 | **56.47** |
| Dev (local; LLM capped by key spend limit) | 0.00 | 10.00 | **10.00** |
| **All environments** | **102.92** | **306.25** | **409.17** |

**Plainly: LLM spend is about 3× the infrastructure cost across all environments, and about 2.4× in production alone.** Budget control is an LLM-spend problem, not a hosting problem.

Owner option (DECISIONS #16): running bulk stages on `claude-sonnet-5` (USD 2 / 10 per MTok) instead would make a campaign 6.50 × 2 + 0.83 × 10 = USD 21.30. That choice belongs to the owner.

## 4. Ceiling and alerts (proposed — owner to confirm)
| Control | Value | Enforced by |
|---|---|---|
| Monthly ceiling, all environments | **USD 450** | Owner sign-off; D7 budget alert |
| Monthly alert threshold | **80% = USD 360** | Grafana alert on cost metrics (D7); DigitalOcean billing alert (D1) |
| Production LLM daily hard stop | **USD 25/day** (`LLM_DAILY_COST_CEILING_USD`) | Application: jobs refuse to start once reached — a hard stop, not a warning (D5/D7) |
| Per-campaign LLM hard stop | **USD 75** | Campaign planner budget (application) |
| Anthropic console spend limit | Production key USD 300/month; staging USD 75; dev USD 10 | Anthropic organisation limits (D1) |
| DigitalOcean billing alert | USD 130/month | DigitalOcean billing alert (D1) |

The ceiling of USD 450 leaves ≈10% headroom over the modelled USD 409.17. If the owner's ceiling is lower, the first lever is the Sonnet option above, not removing staging.
