# VSoftSol GTM Engine — Claude Code Build Prompt

**Product:** VSoftSol GTM Engine (VGE)
**Owner:** Vision Software Solutions (vsoftsol.com)
**Purpose:** An agentic sales & marketing system that reads the company's own Claude Code projects, turns verified product capabilities into market-ready positioning, publishes content to the website and social channels, researches who actually needs these tools, and runs compliant outbound to turn that demand into pipeline.

---

## 0. HOW TO USE THIS DOCUMENT

This is the **source doctrine** for the build. Paste Section 1–5 into Claude Code at the start of the project, then run **one phase per session** using the phase prompts in Section 8.

**Governance clause — Claude Code must obey:**

1. Do **not** collapse, merge, skip or "simplify" phases to finish faster. Every phase ships complete, tested and verified.
2. Do **not** substitute a quicker library, a stub, a mock, or a TODO for real functionality. If something cannot be built as specified, **stop and report**, do not silently downgrade.
3. Every phase ends with tests written, tests passing, and a written verification report committed to `docs/verification/`.
4. No phase may begin until the previous phase's exit gate is signed off in `docs/verification/PHASE_GATES.md`.
5. The final phase is a full **software quality verification** pass over the entire system, performed with the mindset of an independent QA lead, not the author.
6. Ask before inventing scope. Prefer a clarifying question over an assumption.

---

## 1. SYSTEM MISSION

Build a production-grade, self-hosted agentic platform that:

1. **Inventories** selected Claude Code project folders / repositories owned by Vision Software Solutions.
2. **Extracts verified capabilities** from the actual code, docs, specs and release notes — never from imagination.
3. **Researches the market**: who has the pain each tool solves, which segments, which industries, which job titles, which buying triggers, which competitors they use today.
4. **Positions and messages** each product against that market.
5. **Produces marketing assets**: website pages, feature pages, blog posts, comparison pages, release notes, changelogs, social posts, one-pagers, demo scripts, email sequences.
6. **Publishes** to the website (via reviewed pull request) and to social channels (via an approval queue).
7. **Builds target account and contact lists** from lawful public sources, with compliance gates.
8. **Runs outbound** — drafts, personalises, queues for human approval, tracks replies, books demos.
9. **Manages pipeline** — accounts, opportunities, stages, follow-ups, win/loss.
10. **Measures** — traffic, conversions, attribution, campaign ROI — and feeds results back into the next campaign cycle.

**Success condition:** a non-technical operator at VSoftSol can run one command, review a queue, approve items, and see qualified inbound and outbound conversations appear — with every public claim traceable to real product evidence.

---

## 2. PRODUCT PORTFOLIO TO MARKET

The system reads these from a registry file, not from hard-coded constants. Seed `config/portfolio.yaml` with the current VSoftSol network product line:

| Product | Category | One-line value |
|---|---|---|
| VSoftSol Network Configuration Backup | Config backup & restore (Cisco IOS/IOS-XE, SSH, scheduled + manual, diff, audit log) | Never lose a device config again |
| NetworkVault | Multi-tenant config backup, recovery, compliance & automation for enterprises and MSPs, incl. SFTP push/pull | Config assurance at MSP scale |
| Windows Syslog Manager | Network-device syslog collection, retention, compression, RBAC web UI | Searchable device logs without a SIEM bill |
| VSoftSol Network Monitor | Network monitoring product for client sale | Know before your users call |
| VSoft Support | Remote IT support platform — web control plane + Windows endpoint agent, attended & unattended, consent-first | Support any Windows endpoint, safely |
| Network Incident Agent | Multi-agent network troubleshooting & incident response (Cisco, Check Point, Fortinet, cloud edge), Jira-backed | Triage incidents in minutes, not hours |

Each entry carries: `repo_path`, `repo_url`, `status` (alpha/beta/GA), `version`, `licensing_model`, `deployment` (on-prem / self-hosted / SaaS), `target_segments`, `marketable` (bool), `evidence_root`.

**Rule:** a product with `marketable: false` is analysed but never published about. New products are added by editing this file only — no code change.

---

## 3. NON-NEGOTIABLE GUARDRAILS

These are enforced in code, not just documented. Violations must fail a build, not produce a warning.

### 3.1 Truth in marketing
- **Claim Ledger:** every public claim (headline, bullet, benchmark, comparison, spec) must be linked to an evidence record — a file path, test result, benchmark run, doc section or commit SHA in the product repo.
- Unsupported claim → content generation **fails** with the offending claim named. No "best-in-class", "military-grade", "99.99% uptime" unless measured and cited.
- **Zero fabrication:** no invented customers, logos, testimonials, case studies, review counts, awards, or user numbers. Placeholders must be visibly marked `[UNVERIFIED — DO NOT PUBLISH]` and blocked by the publish gate.
- Competitor comparisons must cite the competitor's own public documentation with a retrieval date, and must be re-verified before each publish.

### 3.2 Outbound compliance
- Canada **CASL**, US **CAN-SPAM**, EU/UK **GDPR/PECR** rules encoded as a pre-send checklist: lawful basis recorded, sender identity and physical address present, functioning unsubscribe, honest subject line, no misleading headers.
- **Business contacts from lawful public sources only.** No purchased lists, no scraping behind logins, no credential use, no bypassing rate limits, robots.txt or terms of service.
- Global **suppression list** (unsubscribes, bounces, complaints, competitor domains, do-not-contact) checked before every send. Suppression is permanent and never auto-expires.
- Frequency caps per contact and per domain. Hard stop on reply, opt-out, or bounce.
- PII minimisation: store business contact data only, encrypt at rest, define retention, support deletion on request.

### 3.3 Human in the loop
- The system **never** sends an email, publishes a page, or posts to social media autonomously. Every outbound artefact enters an **approval queue** and requires a recorded human decision (approver, timestamp, diff).
- Website changes ship as pull requests against the site repo with a Vercel preview link — never a direct push to production.
- An "emergency stop" command halts all queues, schedulers and integrations immediately.

### 3.4 Engineering discipline
- No secrets in code or git. Secrets come from environment / OS keyring only; `.env.example` documents every variable.
- All external calls: timeouts, retries with exponential backoff and jitter, circuit breakers, rate limiting, structured logging with correlation IDs.
- Structured audit log of every agent action: who/what/when/why/inputs/outputs/cost.
- Reproducibility: pinned dependencies, deterministic seeds where possible, all LLM prompts versioned in `prompts/` and referenced by ID.

---

## 4. TARGET ARCHITECTURE

### 4.1 Stack
- **Core:** Python 3.12, FastAPI (control plane API), Typer (CLI), Pydantic v2 (all I/O contracts).
- **Persistence:** PostgreSQL 16 via SQLAlchemy 2.x + Alembic migrations. SQLite supported for single-operator local mode behind the same repository interface.
- **Queue/scheduler:** Redis + RQ (or APScheduler in local mode) for campaign jobs, retries and rate limits.
- **Agent layer:** Claude Code subagents defined in `.claude/agents/`, plus a Python orchestrator for scheduled/unattended runs.
- **Operator console:** Next.js 14 + TypeScript + Tailwind, served locally; approval queues, pipeline board, campaign dashboards.
- **Website publishing target:** the existing vsoftsol.com Next.js site on Vercel, DNS on Cloudflare. Content published as MDX + front-matter through a GitHub PR.
- **Email:** transactional/outbound provider abstracted behind an `EmailGateway` interface. **Note the current constraint:** the Zoho Mail Forever Free plan on vsoftsol.com has no IMAP/POP, so Phase 10 must implement a `DraftOnlyGateway` (writes approved drafts for manual send) **and** an SMTP/API gateway, selectable by config, so the system works today and scales when the mail plan is upgraded.
- **Testing:** pytest, pytest-asyncio, pytest-cov, schemathesis (API contract), Playwright (console + published pages), Vitest for TS, Locust for load.
- **Quality:** ruff, black, mypy --strict, bandit, pip-audit, ESLint, tsc --noEmit. All wired into pre-commit and CI.

### 4.2 Repository layout

```
vsoftsol-gtm-engine/
├── CLAUDE.md                     # doctrine + guardrails for every session
├── AGENTS.md                     # same, for Codex-style runtimes
├── README.md
├── .claude/
│   ├── agents/                   # subagent definitions (Section 5)
│   └── commands/                 # slash commands (Section 6)
├── config/
│   ├── portfolio.yaml            # products to analyse/market
│   ├── channels.yaml             # website, social, email channel config
│   ├── icp.yaml                  # ideal customer profiles (generated, human-editable)
│   └── compliance.yaml           # jurisdictions, retention, caps, suppression sources
├── src/vge/
│   ├── core/                     # config, logging, db, errors, audit, secrets
│   ├── intelligence/             # repo scanners, capability extraction, claim ledger
│   ├── research/                 # market research, ICP, competitor intel
│   ├── positioning/              # messaging, narratives, pricing inputs
│   ├── content/                  # generators: pages, posts, releases, social, email
│   ├── publishing/               # github PR pipeline, social queue, scheduler
│   ├── prospecting/              # account/contact discovery, enrichment, scoring
│   ├── outreach/                 # sequences, personalisation, compliance gate, send
│   ├── pipeline/                 # CRM: accounts, opps, stages, activities
│   ├── analytics/                # metrics, attribution, reporting
│   ├── orchestration/            # campaign planner, job runner, emergency stop
│   └── api/                      # FastAPI control plane
├── console/                      # Next.js operator console
├── prompts/                      # versioned LLM prompt templates
├── tests/{unit,integration,e2e,fixtures}/
├── docs/
│   ├── architecture/
│   ├── runbooks/
│   ├── verification/             # per-phase reports + PHASE_GATES.md
│   └── compliance/
└── ops/                          # docker-compose, CI, migrations, seed data
```

---

## 5. AGENT ROSTER

Define each as a Claude Code subagent with an explicit tool allow-list and a written "must not" section.

| # | Agent | Responsibility | Hard limits |
|---|---|---|---|
| 1 | **Portfolio Analyst** | Scan selected repos; extract features, supported devices, install requirements, limitations, roadmap; produce Capability Registry with evidence links | Read-only on product repos. Never edits product code. Never infers a feature from a filename alone |
| 2 | **Evidence & Claim Auditor** | Owns the Claim Ledger; approves or rejects every claim; re-verifies on each release | Cannot be bypassed. Rejections are final until new evidence is supplied |
| 3 | **Market Researcher** | Segments, buyer personas, pains, triggers, budget owners, channels, communities, regulatory drivers (PCI-DSS, NIS2, SOC 2, HIPAA config-audit needs) | Cites sources with retrieval dates. Flags low-confidence findings rather than smoothing them over |
| 4 | **Competitive Analyst** | Competitor matrix, pricing posture, positioning gaps, win themes, honest weaknesses of our own tools | No disparagement, no unverified competitor claims |
| 5 | **Positioning Strategist** | Category choice, value proposition, message hierarchy, proof points, objection handling per persona | Must reconcile with the Claim Ledger |
| 6 | **Content Studio** | Website pages, feature pages, blog/SEO articles, release notes, comparison pages, docs-marketing | No claim not in the ledger. Brand voice file enforced |
| 7 | **Web Publisher** | Renders MDX, opens PRs to the site repo, attaches Vercel preview, runs Lighthouse/a11y/link checks | Never pushes to main. Never publishes without approval |
| 8 | **Social Distributor** | LinkedIn/X/YouTube/Reddit-appropriate posts, thread variants, posting calendar | Drafts only into the approval queue. No engagement farming, no astroturfing, no undisclosed promotion in communities |
| 9 | **Prospect Researcher** | Target account discovery, firmographic fit, tech-stack signals, buying triggers, ICP scoring | Lawful public sources only. Compliance gate before any contact record is stored |
| 10 | **Outreach Writer** | Personalised first-touch and follow-up sequences per persona and product | Every message passes the compliance checklist before queueing |
| 11 | **Sales Enablement** | One-pagers, pitch deck outlines, demo scripts, ROI/TCO calculator inputs, pricing sheets, trial onboarding, RFP answer bank | Pricing requires human sign-off |
| 12 | **Pipeline Manager** | CRM records, stage transitions, next actions, follow-up reminders, win/loss notes | Never marks a stage without a logged activity |
| 13 | **Analytics Agent** | Channel and campaign metrics, attribution, cohort and funnel reporting, recommendations | Reports what happened, including failures. No vanity-only dashboards |
| 14 | **QA Verification Agent** | Independent test design and execution per phase and at release | May block a release. Reports defects without softening |

**Orchestrator:** the main Claude Code thread acts as **Campaign Commander** — plans, delegates to subagents, enforces gates, and never performs a specialist's job silently.

---

## 6. SLASH COMMANDS

Implement in `.claude/commands/`:

- `/analyze-portfolio` — rescan repos, refresh Capability Registry, diff against last scan, list new marketable features.
- `/research-market <product>` — segments, personas, competitors, demand signals, channel recommendations.
- `/position <product>` — generate/refresh positioning and message hierarchy.
- `/campaign <product> <objective>` — plan a full campaign: assets, channels, schedule, targets, KPIs.
- `/content <type> <product>` — generate a page, post, release note or comparison.
- `/publish-web` — build and open the website PR with preview and quality report.
- `/queue` — show every pending approval with diffs.
- `/prospect <product> <segment>` — build a scored target list.
- `/outreach <list> <sequence>` — draft and queue an outbound sequence.
- `/pipeline` — pipeline state, stalled deals, today's follow-ups.
- `/report <period>` — performance report with attribution and recommendations.
- `/verify <phase>` — run that phase's verification protocol and write the report.
- `/stop` — emergency stop: halt all queues, schedulers and integrations.

---

## 7. STANDARD PHASE PROTOCOL

Every phase in Section 8 follows this and is not complete until all seven steps are done.

1. **Plan** — restate objective, list deliverables, list risks, list assumptions to confirm. Write `docs/verification/PHASE_<n>_PLAN.md`.
2. **Design** — data models, interfaces, error paths, security considerations. Document decisions in `docs/architecture/`.
3. **Implement** — production-quality code: typed, documented, handles failure, no stubs, no dead code, no copy-paste duplication.
4. **Test** — unit (≥85% line coverage on new modules, and every branch of every compliance/guardrail check covered), integration against real local services (Postgres/Redis in Docker), and e2e for any user-visible flow. Include negative tests, boundary tests and at least three adversarial cases per guardrail.
5. **Verify** — run the full quality gate: `ruff`, `black --check`, `mypy --strict`, `bandit`, `pip-audit`, `pytest --cov`, plus TS checks where relevant. All green, no suppressions added to silence a finding.
6. **Report** — write `docs/verification/PHASE_<n>_VERIFICATION.md` containing: what was built, how it was tested, commands run, results, coverage numbers, known limitations, defects found and fixed, residual risks.
7. **Gate** — append the phase result to `docs/verification/PHASE_GATES.md`, commit, and tag `v0.<n>.0`. Then stop and hand back for review.

**Definition of Done (applies to every phase):** feature works end-to-end for a real input; failure modes handled and tested; observability in place; docs updated; quality gate green; verification report written; nothing left mocked that was meant to be real.

---

## 8. PHASE PLAN

### Phase 0 — Foundation & Doctrine
Scaffold the repository. Write `CLAUDE.md` and `AGENTS.md` encoding Sections 1, 3 and 7. Create all agent definitions and command stubs. Set up Docker Compose (Postgres, Redis), pre-commit, CI workflow, `.env.example`, logging, config loader, error taxonomy, audit-log writer, and the secret-handling module. Seed `config/portfolio.yaml`.
**Exit gate:** `docker compose up` works; CI green on an empty test suite plus foundation tests; audit log records a sample action; no secret can be read from a file committed to git (test proves it).

### Phase 1 — Data Core
Design and migrate the full schema: products, capabilities, evidence, claims, segments, personas, competitors, accounts, contacts, suppressions, content items, approvals, campaigns, activities, opportunities, metrics, audit events. Repository layer with SQLite/Postgres parity. Seed and fixture data.
**Exit gate:** migrations up/down clean; repository test suite passes on both backends; referential integrity and retention fields verified.

### Phase 2 — Product Intelligence
Build repo scanners: README/spec/docs parsing, code-structure analysis, API/CLI surface extraction, dependency and platform requirements, test-suite inspection, release notes and git history. Output a **Capability Registry** per product: feature, description, maturity, supported platforms, limitations, evidence pointers (path + line range or commit SHA), confidence score.
**Exit gate:** run against at least three real VSoftSol repos; every extracted capability resolves to a real evidence location; a deliberately false capability injected into a test fixture is correctly rejected.

### Phase 3 — Claim Ledger & Truth Gate
Implement the ledger and the `ClaimAuditor`. Every claim gets: text, product, type (functional / performance / comparative / compliance), evidence links, verification status, verifier, date, expiry. Build the gate API that all downstream content generation must call. Add the `[UNVERIFIED]` blocker.
**Exit gate:** adversarial test set of 20+ claims (true, exaggerated, unfalsifiable, competitor-derived, expired) classified correctly; content generation demonstrably cannot bypass the gate.

### Phase 4 — Market Research Engine
Implement research workflows per product: segment definition, persona construction (titles, responsibilities, pains, buying triggers, budget authority), demand-signal collection from lawful public sources (job postings mentioning the relevant stack, community questions, vendor forum threads, compliance deadlines), geography prioritisation, channel mapping, and an ICP scoring model. Persist to `config/icp.yaml` plus the database, with sources and retrieval dates.
**Exit gate:** produce a complete, cited research dossier for two products; low-confidence findings are visibly flagged; all sources fetched in compliance with robots.txt and ToS (test proves the fetcher honours both).

### Phase 5 — Competitive Intelligence & Positioning
Competitor registry and feature/pricing matrix with citations and retrieval dates. Gap analysis. Generate positioning per product: category, target, value proposition, three-level message hierarchy, proof points, differentiators, honest weaknesses, objection handling, and per-persona messaging variants.
**Exit gate:** positioning docs generated for the full marketable portfolio; every differentiator traces to the Claim Ledger; a stale competitor citation triggers a re-verification warning.

### Phase 6 — Content Studio
Brand voice file and content templates. Generators for: website home/product/feature pages, technical blog posts, SEO articles targeting researched keywords, comparison pages, release notes, changelogs, FAQ, and documentation-adjacent marketing. SEO module: keyword research, title/meta, internal linking, schema.org markup, readability scoring. Multi-variant output for testing.
**Exit gate:** generate a full content set for one product; every asset passes the truth gate, SEO checks and readability thresholds; regenerating with the same inputs is stable and diffable.

### Phase 7 — Website Publishing Pipeline
GitHub integration against the vsoftsol.com site repo: branch, MDX + front-matter write, asset handling, PR creation with a summary of claims and evidence, Vercel preview link capture, and automated pre-merge checks (build, broken links, Lighthouse performance/SEO/a11y thresholds, sitemap and robots correctness). Rollback runbook.
**Exit gate:** a real PR opened against a test branch with a passing preview and quality report; direct-push attempts are blocked by code and proven by test; rollback exercised.

### Phase 8 — Social & Community Distribution
Channel adapters (LinkedIn, X, YouTube description/community, Reddit, dev communities) with per-channel formatting, length and tone rules. Content calendar and scheduler. Approval queue integration. Disclosure rules for self-promotion in communities. UTM tagging.
**Exit gate:** a two-week calendar generated and queued; nothing can post without a recorded approval; rate limits and channel policy checks enforced and tested.

### Phase 9 — Prospecting Engine
Target-account discovery by segment and geography from lawful public sources; firmographic and technographic fit signals (e.g. organisations running multi-vendor network estates, MSPs, regulated SMEs); trigger detection (hiring network engineers, compliance deadlines, published incidents, migrations); ICP scoring and ranking; contact-role identification. Compliance gate before any record is persisted; suppression check on write and on read.
**Exit gate:** produce a scored list for two segments; every record carries source and lawful-basis metadata; suppressed and out-of-policy records are provably excluded; deletion request removes all traces (test proves it).

### Phase 10 — Outbound Engagement
Sequence engine (first touch, value follow-ups, break-up), deep personalisation from research + triggers + the product's actual capabilities, `EmailGateway` abstraction with `DraftOnlyGateway` and SMTP/API implementations, compliance checklist enforcement per message, unsubscribe handling, bounce/complaint processing, reply detection and routing, frequency caps, send-window scheduling.
**Exit gate:** a full sequence drafted, compliance-checked and queued; a non-compliant message is rejected with a named reason; unsubscribe and bounce both write to the permanent suppression list; nothing sends without approval.

### Phase 11 — Sales Enablement & Conversion
One-pagers and battlecards per product and persona; demo script and demo environment checklist; ROI/TCO calculator; pricing sheet scaffolding (human sign-off required); trial/POC onboarding flow; RFP/security-questionnaire answer bank sourced from real product documentation; lead capture and routing from the website.
**Exit gate:** complete enablement kit for two products; every number in the ROI model is input-driven and documented — no hard-coded flattering assumptions; RFP answers all cite product evidence.

### Phase 12 — Pipeline & CRM
Accounts, contacts, opportunities, stages, activities, tasks and reminders. Stage-transition rules requiring logged evidence. Stalled-deal detection. Win/loss capture with reasons. Forecast view. Export/import and optional sync interface for an external CRM.
**Exit gate:** a deal driven from first touch to closed-won and closed-lost through the API and console; audit trail complete; reminders fire correctly under time-travel tests.

### Phase 13 — Analytics, Attribution & Feedback Loop
Metric collection from the website (privacy-respecting), social, email and pipeline. Funnel and cohort analysis. Multi-touch attribution. Campaign ROI. Automated periodic reports with concrete recommendations that feed back into research, positioning and content priorities.
**Exit gate:** end-to-end attribution demonstrated on seeded data; reports name underperformance explicitly; recommendations are actionable and traceable to data.

### Phase 14 — Orchestration & Operator Console
Campaign planner that composes phases 4–13 into a runnable plan; job scheduler with retries, backoff and dead-letter handling; the Next.js console (approval queues with diffs, pipeline board, campaign dashboards, claim ledger browser, audit log viewer, emergency stop); role-based access; full run history.
**Exit gate:** a complete campaign executed end-to-end in a staging configuration with human approvals at every gate; `/stop` halts everything within seconds and is proven by test; console passes Playwright e2e and accessibility checks.

### Phase 15 — Final Software Quality Verification (independent QA pass)

Act as an independent **software quality verification expert** reviewing this system for the first time, with no loyalty to the code already written. Assume defects exist and go find them.

Perform and document all of the following:

1. **Requirements traceability** — map every requirement in Sections 1–3 to implementation and to the test that proves it. Any unmapped requirement is a defect.
2. **Full regression** — entire suite, all layers, on a clean environment from a fresh clone, following only the README. Document every step where the docs are wrong or incomplete.
3. **Integration verification** — every external integration exercised against a real sandbox or a contract-tested fake: GitHub, Vercel preview, email gateways, social adapters, Postgres, Redis.
4. **End-to-end business scenarios** — at minimum: (a) new product added to the portfolio → researched → positioned → content generated → published → prospected → outbound → demo booked → opportunity won; (b) the same flow where compliance rejects the outbound; (c) a claim fails verification mid-campaign.
5. **Guardrail assurance** — deliberately attempt to bypass every guardrail in Section 3 (unverified claim, direct push, unapproved send, suppressed contact, missing lawful basis, secret in code). Each attempt must fail closed. Document each attempt and result.
6. **Security review** — authentication and authorisation on the console and API, input validation, injection and SSRF surfaces, secret handling, dependency CVEs, least privilege on tokens, rate limiting, audit completeness.
7. **Performance and resilience** — load test the API and job runner, verify behaviour under external-service failure, timeouts, partial outage, queue backlog, and database contention. Record throughput and latency baselines.
8. **Data integrity** — migration up/down on populated data, backup and restore, retention and deletion, no orphaned records.
9. **Usability** — walk the operator console as a non-technical user; note every point of confusion as a defect with a severity.
10. **Defect log** — `docs/verification/FINAL_QA_REPORT.md` with every finding: ID, severity (Critical/High/Medium/Low), reproduction steps, evidence, root cause, fix or accepted risk with rationale.

**Release gate:** zero Critical and zero High defects open. Every Medium is either fixed or explicitly accepted in writing by the owner. Produce a signed release readiness statement, tag `v1.0.0`, and write the production runbook (install, configure, operate, monitor, back up, upgrade, roll back, emergency stop).

---

## 9. FIRST SESSION INSTRUCTION

> Read this entire document. Do not write code yet. Produce:
> 1. Your understanding of the mission in your own words.
> 2. Any ambiguity or missing decision you need resolved before Phase 0, with your recommended answer for each.
> 3. A risk register for the build.
> 4. The Phase 0 plan per Section 7, step 1.
>
> Then stop and wait for approval. After approval, execute Phase 0 only — completely, tested and verified — and stop again at the gate.
