# Sizing and Cost

Produced in Phase D0 (2026-09-27). Revised 2026-09-28 (near-free hosting) and **2026-09-30: USD 0 ceiling** (DECISIONS #23). Provider limits retrieved 2026-09-27/30; D2 re-confirms each one before anything is created.

## 1. Workload assumptions
| Assumption | Value | Why it matters |
|---|---|---|
| Operators | 1 | Console load negligible |
| AI workload | **None until the LLM provider decision (DECISIONS #16)** | The host runs data, approvals, stop control, suppression and the console only |
| Outbound volume | Hand-sent by the owner from draft-only output (DECISIONS #7) | Volume is bounded by the owner's time; the compliance caps still apply |
| Data volume, year 1 | Postgres < 5 GB | Fits the 20 GB free object storage with 7 days of WAL |

## 2. Resource sizing

### Production host — OCI Always Free, Ampere A1, 2 OCPU / 12 GB (arm64), `ca-toronto-1`
Free allowance per Oracle docs (retrieved 2026-09-28): 1,500 OCPU-h + 9,000 GB-h/month (= 2 OCPU / 12 GB), 200 GB block storage, 20 GB object storage (Always-Free-only accounts), 10 TB egress.

Memory budget (Compose `limits`):

| Container | Memory limit |
|---|---|
| worker | 2048 MB (idle until an LLM provider exists; still runs non-LLM jobs such as retention) |
| postgres (self-hosted, DECISIONS #3) | 2048 MB |
| api | 1536 MB |
| console | 1024 MB |
| scheduler | 512 MB |
| redis | 512 MB |
| wal-g / backup sidecar | 256 MB |
| dispatcher | 256 MB |
| egress-proxy, caddy, cloudflared | 128 MB each |
| **Total limits** | **8576 MB** of 12288 MB, leaving ≈3.6 GB for the OS and page cache |

**Idle-reclaim note (DECISIONS #21):** without AI work, CPU and network will sit well below Oracle's 20% threshold. Memory is what keeps the instance out of reclamation: Postgres shared buffers + page cache + the resident stack must stay above 20% of 12 GB (≈2.5 GB). D7 alerts if memory p95 approaches that line. No synthetic load is generated.

**Scale-up trigger:** any sustained resource pressure is a signal to revisit the USD 0 ceiling; there is no free headroom beyond 2 OCPU / 12 GB.

### Dev and staging — GitHub Codespaces (DECISIONS #13, #22)
Free allowance: 120 compute hours + 15 GB storage per month; usage is blocked, not billed, when it runs out (no payment method on the account). Planning budget: **60 h/month** on a 2-core machine, shared by dev work, D2 tooling and staging rehearsals.

## 3. Monthly cost per environment

| Environment | Item | Basis | USD/month |
|---|---|---|---|
| Production | A1 compute, 100 GB block, object storage | OCI Always Free | 0.00 |
| Production | Off-provider backup copy | Backblaze B2 free tier (≤10 GB) or equivalent; confirmed in D4 | 0.00 |
| Production | Cloudflare Tunnel + Access, Grafana Cloud free, external uptime free tier, GitHub Free, GHCR | free tiers | 0.00 |
| Production | Sending subdomain of vsoftsol.com | existing domain | 0.00 |
| Production | Email sending | draft-only; the owner sends by hand | 0.00 |
| Production | LLM | deferred (DECISIONS #16); nothing calls an LLM | 0.00 |
| Staging | Codespaces | free allowance | 0.00 |
| Dev | Codespaces | free allowance | 0.00 |
| **All environments** | | | **0.00** |

**Plainly:** USD 0 is achievable only because the system currently has **no AI and no automated sending**. It is an approval, suppression and publishing platform waiting for its AI decision. When #16 is decided, this model is re-run and any non-zero figure needs owner approval.

For the record, the modelled alternatives were: USD 409.17/month (plan defaults, 2026-09-27) and USD 319.78/month (free hosting + Opus 5, 2026-09-28).

## 4. Ceiling and alerts
| Control | Value | Enforced by |
|---|---|---|
| Monthly ceiling | **USD 0** | DECISIONS #23 |
| OCI | Always-Free-only tenancy (cannot incur charges) + budget alert at **USD 0.01** | OCI Budgets (D1) |
| GitHub | **No payment method** on the account: Codespaces and Actions minutes block rather than bill | GitHub billing settings (D1) |
| Cloudflare, Grafana Cloud, uptime monitor, Backblaze | Free plans, no payment method where the provider allows it | D1 account setup |
| LLM | No provider account with billing | DECISIONS #16 |
| Monthly check | Every provider's billing page reviewed once a month; any charge is an incident | Plan §6 monthly operations |
