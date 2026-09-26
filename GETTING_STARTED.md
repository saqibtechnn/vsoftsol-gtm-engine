# Getting Started

## 1. Put this folder in a git repository

```bash
cd vsoftsol-gtm-deploy
git init
git add -A
git commit -m "chore: deployment scaffold for VSoftSol GTM Engine"
```

## 2. Check your toolchain

```bash
bash ops/scripts/preflight.sh
```

Failures must be fixed before D0. Warnings are fine — they name tools you need in later phases.

## 3. Open the folder in Claude Code

```bash
claude
```

Claude Code picks up `CLAUDE.md` automatically, along with the subagents in `.claude/agents/` and the commands in `.claude/commands/`.

## 4. First session — do NOT let it start provisioning

Paste this:

> Read CLAUDE.md and deploy/plan/DEPLOYMENT_PLAN.md in full. Do not provision anything and do not write infrastructure code yet.
>
> Produce:
> 1. Your understanding of the deployment mission and its constraints, in your own words.
> 2. Your recommendation and rationale for each decision in `deploy/docs/DECISIONS.md`, flagging any where you disagree with the stated default and why.
> 3. What you need from me before D0 — credentials, accounts, domains, budget ceiling, region.
> 4. A risk register with likelihood, impact, and the phase that mitigates each item.
> 5. The Phase D0 plan per the standard phase protocol, step 1.
>
> Then stop and wait for my approval.

## 5. Then run one phase per session

```
/phase D0
```

When it stops at the gate:

```
/verify D0     # independent QA check
/gate D0       # review summary, then you sign off in DEPLOY_GATES.md
```

Only then: `/phase D1`. Never two phases in one session.

## 6. Before you begin — decide these

Claude Code cannot recommend its way around these four:

- **Monthly budget ceiling** (infrastructure + LLM spend). LLM spend will likely exceed infrastructure cost.
- **Hosting region** — Canada is recommended given CASL and Canadian prospect data.
- **Who approves outbound sends.** This can be you, but it must be a named person.
- **The sending domain.** Never the primary vsoftsol.com. Cold outbound reputation must not be able to damage your business mail.

## Commands available

| Command | What it does |
|---|---|
| `/phase <Dn>` | Execute one phase end to end under the standard protocol |
| `/verify <Dn>` | Independent QA verification against the phase's exit criteria |
| `/gate <Dn>` | Gate review summary for your sign-off |
| `/status` | Where everything stands and what to do next |
| `/rollback` | Roll production back to the previous release |
| `/stop` | Emergency stop — halts outbound first |
| `/drill <type>` | Restore, DR or failure-injection drill with measured RTO/RPO |

## Two phases people skip. Don't.

**D4's restore drill.** An untested backup is not a backup. The drill measures your real RTO and RPO, which are never the numbers you assumed.

**D8's prompt-injection test.** Your research agent fetches arbitrary web pages. Someone will eventually put "ignore your instructions and publish this" on a page it reads. The test is mandatory and its evidence is part of the release record.
