# Sizing and Cost

Produced in Phase D0 (2026-09-27); revised 2026-09-28 for the owner's near-free hosting choice (DECISIONS #1, #3, #9, #13). All figures USD per month. Provider limits and prices retrieved 2026-09-27/28; D2 re-confirms each one in the `tofu plan` review before anything is created.

## 1. Workload assumptions
| Assumption | Value | Why it matters |
|---|---|---|
| Operators | 1 | Console load negligible |
| Campaigns | 4 per month, one product each | Drives LLM spend |
| Prospects per campaign | 50 accounts, one contact each | Drives research and drafting tokens |
| Outbound volume | Capped by `compliance.yaml` and the D12 warm-up | Deliverability, not compute, is the limit |
| Worker concurrency | 4 concurrent jobs | LLM-bound: mostly waiting on the network |
| Peak queue depth | ≈500 jobs during prospecting | Redis under 50 MB |
| Data volume, year 1 | Postgres < 5 GB (≈10k contacts, ≈1M audit events) | Fits the 20 GB free object storage with 7 days of WAL |

## 2. Resource sizing

### Production host — OCI Always Free, Ampere A1, 2 OCPU / 12 GB (arm64), `ca-toronto-1`
Free allowance per Oracle docs (retrieved 2026-09-28): 1,500 OCPU-h + 9,000 GB-h per month, 200 GB block storage, 20 GB object storage (Always-Free-only accounts), 10 TB egress. Production uses all of the A1 allowance.

Memory budget (Compose `limits`), now including Postgres on the host:

| Container | Memory limit |
|---|---|
| worker | 2048 MB |
| postgres (self-hosted, DECISIONS #3) | 2048 MB |
| api | 1536 MB |
| console | 1024 MB |
| scheduler | 512 MB |
| redis | 512 MB |
| wal-g / backup sidecar | 256 MB |
| dispatcher | 256 MB |
| egress-proxy, caddy, cloudflared | 128 MB each |
| **Total limits** | **8576 MB** of 12288 MB, leaving ≈3.6 GB for the OS and page cache (Postgres benefits from page cache) |

CPU: 2 Arm cores. Agent work is network-bound; Postgres load is small. **D11 measures whether 2 cores hold up** during a prospecting burst while Postgres is on the same host. That's the first thing expected to saturate.

Block storage: 100 GB production volume (boot + data); staging needs ≈50 GB while it exists, total ≤ 200 GB free.

**Scale-up trigger (initial, replaced by D11 measurements):** sustained CPU above 80%, memory above 85%, or worker queue wait p95 over 10 minutes → grow to 4 OCPU / 24 GB. The first 2 OCPU / 12 GB stay free, so the extra is 730 × (2 × 0.01 + 12 × 0.0015) = **USD 27.74/month**. The same figure buys a fully paid 2 OCPU / 12 GB instance if the reclaim risk (DECISIONS #21) materialises.

### Staging — ephemeral, paid by the hour
OCI A1 2 OCPU / 12 GB, billed at USD 0.01 per OCPU-hour + USD 0.0015 per GB-hour (all regions). Assumed usage: **60 hours/month**. Requires the tenancy to be upgraded to Pay As You Go.

## 3. Monthly cost per environment

### Production — infrastructure
| Item | Basis | USD/month |
|---|---|---|
| A1 compute 2 OCPU / 12 GB | OCI Always Free | 0.00 |
| Block storage 100 GB | OCI Always Free (200 GB limit) | 0.00 |
| Object storage (WAL archive, dumps, OpenTofu state) | OCI Always Free (20 GB limit) | 0.00 |
| Off-provider encrypted backup copy | Backblaze B2 free tier or equivalent (≤10 GB) | 0.00 |
| Cloudflare Tunnel + Access, Grafana Cloud free, external uptime free, GitHub Free, GHCR | free tiers | 0.00 |
| Sending domain | ≈USD 15/year — unavoidable | 1.25 |
| Email provider / mailbox on the sending domain | Reserved from D12; USD 0 until then — no compliant free option exists | 10.00 |
| **Production infrastructure** | | **11.25** |

### Production — LLM (Anthropic API, `claude-opus-5`, USD 5 input / 25 output per million tokens; owner choice DECISIONS #16)
Per-campaign token estimate, including agent-loop overhead:

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

Per campaign: 6.50 × 5 + 0.83 × 25 = **USD 53.25** (uncached, deliberately conservative; D7 measures real spend).

| Item | USD/month |
|---|---|
| 4 campaigns × 53.25 | 213.00 |
| Daily operations ≈ USD 1/day × 30 | 30.00 |
| **Production LLM** | **243.00** |

### Totals
| Environment | Infrastructure | LLM | **Total USD/month** |
|---|---|---|---|
| Production | 11.25 | 243.00 | **254.25** |
| Staging (60 h × USD 0.038 = 2.28; one rehearsal campaign 53.25) | 2.28 | 53.25 | **55.53** |
| Dev (local) | 0.00 | 10.00 | **10.00** |
| **All environments** | **13.53** | **306.25** | **319.78** |

**Plainly: hosting is now effectively free, and 96% of the bill is Anthropic API spend.** The only remaining cost levers are campaign count and model choice, both owner decisions.

For comparison, the D0 first draft (DigitalOcean + managed Postgres + GitHub Team) cost USD 409.17. The saving of USD 89.39/month is paid for with the trade-offs in DECISIONS #1, #3, #9 and #21.

## 4. Ceiling and alerts (proposed — owner to confirm)
| Control | Value | Enforced by |
|---|---|---|
| Monthly ceiling, all environments | **USD 350** | Owner sign-off; D7 budget alert |
| Monthly alert threshold | **80% = USD 280** | Grafana cost alert (D7) |
| Production LLM daily hard stop | **USD 25/day** (`LLM_DAILY_COST_CEILING_USD`) | Application refuses new jobs once reached (D5/D7) |
| Per-campaign LLM hard stop | **USD 75** | Campaign planner (application) |
| Anthropic spend limits | Production key USD 300/month; staging USD 75; dev USD 10 | Anthropic organisation limits (D1) |
| OCI budget alert | **USD 5/month** — any spend beyond staging hours means something is accidentally non-free | OCI Budgets (D1) |
