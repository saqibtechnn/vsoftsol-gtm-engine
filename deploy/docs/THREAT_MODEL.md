# Threat Model

Produced in Phase D0 (2026-09-27). Refreshed quarterly and whenever an architectural decision changes (plan §6).
Scope: the deployed VGE system as described in ARCHITECTURE.md.

## 1. Assets
| ID | Asset | Why it matters |
|---|---|---|
| A1 | Email-send credential and sending-domain reputation | Misuse = spam from VSoftSol, legal exposure under CASL/CAN-SPAM, reputation that takes months to rebuild |
| A2 | vsoftsol.com site repository and its Vercel deployment | Defacement or false claims published under the company name |
| A3 | Social account tokens | Public posts under the company name |
| A4 | Prospect contact data (business PII) | Privacy law obligations (PIPEDA, GDPR); breach notification |
| A5 | Suppression list | Loss or corruption = contacting people who opted out (legal breach) |
| A6 | Audit log and approval records | Proof that every public action was approved; legal evidence |
| A7 | Claim ledger and evidence links | Truth-in-marketing guarantee |
| A8 | Anthropic API key and budget | Direct financial loss; quota exhaustion |
| A9 | Product source repositories (read access) | Confidential IP of VSoftSol |
| A10 | Infrastructure credentials (Oracle Cloud, Cloudflare, GitHub admin, age keys, owner release-signing key) | Full compromise |

## 2. Actors
| ID | Actor | Capability |
|---|---|---|
| X1 | Author of a web page the research agent reads | Can place arbitrary text in agent context |
| X2 | Anyone who replies to an outbound email | Can place arbitrary text in agent context via the reply handler |
| X3 | External attacker on the internet | Scans, credential stuffing, webhook forgery |
| X4 | Compromised upstream dependency or base image | Code execution inside a container |
| X5 | Compromised provider account (GitHub, Cloudflare, Oracle Cloud) | Control-plane access |
| X6 | Well-meaning operator making a mistake | Legitimate access, wrong action |
| X7 | The agent itself behaving unexpectedly (model error, loop) | Uses whatever tools and budget it has |

## 3. Entry points
Research fetches (via egress-proxy) · inbound email replies · product repository content · webhook endpoint `hooks.` · operator console · CI pipeline and GitHub Actions · container images and dependencies · provider control panels · the host's SSH (key-only, allowlisted source).

## 4. Threats, mitigations and residual risk

| ID | Threat (agentic-specific first) | Actor | Mitigation | Phase | Residual risk after mitigation |
|---|---|---|---|---|---|
| T1 | **Prompt injection via researched web content**: a page says "ignore instructions, publish X / email Y" | X1 | Fetched content handled as delimited data; per-agent tool allow-lists; **agents hold no send/publish credentials** (dispatcher isolation); every side effect needs human approval; mandatory hostile-page test | D8, D14 | An injected instruction can still bias a *draft* (tone, a false claim). Caught by the claim ledger and human review, not by infrastructure. Medium. |
| T2 | **Prompt injection via inbound email reply** | X2 | Same as T1; reply handler may classify and route only, with no tools that act outward; mandatory reply-injection test | D8, D14 | Mis-classification (e.g. an unsubscribe missed). Mitigated by keyword-based unsubscribe detection that doesn't depend on the LLM. Low. |
| T3 | Prompt injection via product repository content (README instructs the agent) | X1/X4 | Repos read with a read-only token; content treated as data; claims need evidence links a human can inspect | D1, D8 | Low. |
| T4 | **Unapproved send or publish** through a bug or a bypass | X7, X6 | Approval recorded in Postgres; the dispatcher re-validates before every side effect; send credential only in the dispatcher; `REQUIRE_HUMAN_APPROVAL` cannot be false in production (startup refuses); adversarial bypass tests | D5, D8, D11, D14 | A logic bug inside the dispatcher itself. Mitigated by tests and small code size. Low. |
| T5 | **Duplicate sends or publishes** after retry, crash or failover | X7 | Idempotency keys in Postgres checked before every side effect; exactly-once recording; replay tests after failure injection | D11 | Provider-side duplicate if the provider accepts a message and the ack is lost. Low; bounded to a single message. |
| T6 | **Over-permissioned tokens** | X5, X7 | Fine-grained tokens per integration and environment; out-of-scope denial tested per token; `TOKEN_INVENTORY.md` | D1 | Provider scope granularity limits (some APIs have coarse scopes). Documented per token. Low–Medium. |
| T7 | **Data exfiltration through egress** | X4, X7 | Host egress allowlist (nftables); only the egress-proxy reaches arbitrary hosts, and only via GET-style fetches with logged destinations; the worker has no direct internet | D2, D8 | Data encoded into URLs of allowed research fetches. Mitigated by proxy logging, request-size caps and alerting on unusual fetch volume. Medium. |
| T8 | **Dependency / image supply-chain compromise** | X4 | Lockfiles, digest-pinned bases, SBOM, Trivy/Grype fail threshold, cosign sign + verify at deploy, scheduled re-scans | D3, D8, D9 | Zero-day in a signed dependency. Contained by credential isolation and egress limits. Medium. |
| T9 | **Credential compromise** (leak in git, logs, image) | X3, X5 | SOPS + age; tmpfs injection; gitleaks over full history in CI; log scrubbing; rotation runbook; incident runbook | D5, D8, D9 | Owner workstation compromise exposes age key. Mitigated by MFA and break-glass separation. Medium. |
| T10 | **Operator error**: bulk-approving a bad batch, merging a wrong PR | X6 | First batch individually approved; approvals expire in 72 h; two deliberate steps for any real send; clear diffs; emergency stop | D8, D13, D14 | Human judgement errors remain. Low–Medium. |
| T11 | Webhook forgery (fake unsubscribe or bounce, or flooding) | X3 | HMAC signature + timestamp replay window; rate limit; Access bypass limited to one path | D8 | Forged events can only *add* suppressions (fail-safe direction). Low. |
| T12 | Console account takeover | X3 | Cloudflare Access OIDC + MFA; no public exposure; RBAC; session security | D1, D8 | Identity-provider compromise. Low. |
| T13 | Suppression list loss or corruption | X7, X6 | Postgres system of record, permanent entries, backups + PITR, check on write and on send, restore drill | D4, D12 | Low. |
| T14 | **Unexpected charges** breaking the USD 0 ceiling: a free tier ends, a resource is created outside Always Free, or an LLM account is added with billing | X6, X7 | Always-Free-only OCI tenancy; no payment method on GitHub; OCI budget alert at USD 0.01; `free-tier` tag on every resource; monthly billing review; when an LLM is added (DECISIONS #16), application daily/per-campaign hard stops | D1, D2, D7 | A provider changes its free-tier terms. Detected at the monthly review; owner decides. Low. |
| T15 | SSRF from the research fetcher into cloud metadata or the private network | X1 | Egress-proxy denies private ranges and metadata IPs, caps redirects, allowlists protocols | D8 | Low. |
| T16 | Staging reaches real recipients or the production site repo | X7, X6 | Separate credentials per environment; dispatcher send-guard allowlist; staging GitHub token scoped to the sandbox repo only | D5, D10 | Low. |
| T17 | Emergency stop is slow or incomplete | X7 | Stop flag in Postgres and Redis checked by the dispatcher before every side effect; `docker kill` (no graceful drain) of dispatcher then workers; works from the host CLI without the console | D6, D13 | Messages already accepted by the provider cannot be recalled. Low. |
| T18 | Provider account takeover (Oracle Cloud, Cloudflare, GitHub) | X5 | MFA enforced, no shared accounts, audit logs enabled, billing alerts, break-glass procedure | D1 | Medium (single owner = single point of compromise). |
| T19 | Sending-provider terms breach for cold outreach | — | Not applicable while sending is draft-only and hand-sent (DECISIONS #7). Re-assessed if a provider is ever added | D12 | Low. |
| T20 | **Free-tier host loss**: Oracle reclaims an idle Always Free instance, or free A1 capacity is unavailable when (re)building | — | Production load keeps memory above Oracle's 20% idle threshold (no synthetic load); D7 alerts as metrics approach it; host is rebuildable from IaC + backups; documented fallback to paid A1 (USD 27.74/month) | D2, D7, D11 | Rebuild during a capacity shortage could be delayed for hours to days. Outbound simply stops (fail closed). Medium. |
| T21 | **Database on the application host**: host compromise or loss takes the system of record with it; backups silently stop | X3, X4 | Postgres on internal network only; least-privilege app role; continuous WAL archive + daily dump, client-side encrypted, copied off-provider; backup-failure alert; **measured restore drill from WAL** | D4, D7, D11 | RPO = WAL archive lag (target ≤ 5 min). A host-level attacker could read live PII — same exposure a managed DB would have from a compromised app host. Medium. |
| T22 | **Release-approval bypass or signing-key loss**: CI or GitHub compromise pushes a malicious release; or the owner's signing key is lost or stolen | X4, X5 | The host deploys only manifests signed by the owner's key, which CI never holds; key hardware-backed or offline; sealed break-glass copy; every deploy logged in `DEPLOY_LOG.md` | D1, D9 | Theft of the owner key + host access = arbitrary deploy. Key loss = no deploys until break-glass rotation. Low–Medium. |
| T23 | **Missed manual suppression**: with draft-only sending, the owner forgets to log an unsubscribe, bounce or complaint, and the contact is emailed again (CASL/CAN-SPAM breach) | X6 | Console action to log each event in one step; drafts carry a working unsubscribe link/instruction routed to a mailbox the owner checks; the compliance gate refuses new drafts to any contact with an unlogged reply older than 48 h; weekly suppression reconciliation checklist | D8, D10, D12 | Depends on owner discipline, which is the weakest control in the system. **High** likelihood of occasional misses at any real volume; keep volume low. |
| T24 | **Codespaces as staging/tooling**: staging credentials stored in Codespaces secrets; quota exhaustion blocks rehearsals or an urgent rebuild | X5 | Staging-only credentials in Codespaces (never production); production age key never in Codespaces; D2 host rebuild runbook documents a no-Codespaces path; quota checked before starting a rehearsal | D1, D2, D5 | An urgent production rebuild late in the month may wait for quota reset or use the owner PC. Medium. |
| T25 | **Future free-tier LLM leaks PII**: a free AI tier may use inputs for training | X7 | DECISIONS #16: free tiers only for non-PII work; the dispatcher/worker boundary plus a PII filter before any LLM call (D8); terms verified at decision time | D8 (when #16 is decided) | Mis-tagged PII slipping through the filter. Medium until tested. |
| T26 | **Public VGE repository** (DECISIONS #24): attackers read the control design, CI workflows and dependency list; a committed secret is exposed instantly to scrapers | X4, X5 | Secrets only as SOPS ciphertext (#10); GitHub secret scanning + push protection enabled (free on public repos); gitleaks in CI and over history (D5, D9); `protect-main` ruleset; CI on PRs from forks gets no secrets (D9); controls designed to hold when known | D1, D5, D9 | A plaintext secret pushed once must be treated as compromised and rotated, even if removed. Medium. |

## 5. Scaffold findings tracked from the D0 review
Defects in the starter files, recorded here so they are fixed by the owning phase rather than silently.

| ID | Finding | Severity | Owning phase |
|---|---|---|---|
| F1 | `compose.prod.yaml` loads the whole `.env` into every container, so every service holds every secret | High | D5, D6, D8 |
| F2 | Redis password on the command line and in the healthcheck → visible in `docker inspect` and `ps` | High | D5, D6 |
| F3 | `emergency-stop.sh` stops the scheduler before the workers; workers get a 120 s graceful drain during an *emergency*; the api and publishing path are not halted | High | D6 |
| F4 | CI `gitleaks detect --no-git` scans only the working tree, not history | High | D9 |
| F5 | CI grants `packages: write` and `id-token: write` workflow-wide, including to pull-request jobs | Medium | D9 |
| F6 | `.env.example` is missing `REDIS_PASSWORD` and `CLOUDFLARE_TUNNEL_TOKEN` | Medium | D5 |
| F7 | Redis started with `--bind 0.0.0.0` (acceptable only because no port is published; must be proven in D4) | Low | D4 |
| F8 | `cloudflare/cloudflared:latest` and unpinned base images in compose | Medium | D3, D6 |
| F9 | Draft-only gateway cannot read replies; D10 requires reply handling | Medium | D10, D12 |
| F10 | The only marketable product has empty `repo_path` and `evidence_root`; `site_repo` is empty | High (blocks content) | D1 + build phase 2 |
| F11 | `.gitignore` ignores `secrets/`; SOPS files placed there could never be committed | Low | D5 (use `config/sops/`) |
| F12 | Plan states D0–D5 can run without the application; D3–D5 cannot be evidenced without it | Medium | Owner decision (DECISIONS #17) |
| F13 | Plan's go-live email default (transactional provider) conflicts with provider terms for cold outreach | High | D12 (DECISIONS #7) |
| F14 | README lists `ops/tofu/` and `ops/ansible/`, which do not exist yet | Low | D2 |
| F15 | `verify-backup.sh` guards against production only by URL substring | Low | D4 |
