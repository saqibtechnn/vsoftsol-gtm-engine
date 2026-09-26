---
description: Report current deployment state across all phases and environments
---

Report, briefly:
- Phase gates: completed, in progress, blocked (from `DEPLOY_GATES.md`).
- Current release per environment (version + digest) from `DEPLOY_LOG.md`.
- Open defects by severity.
- Outstanding owner decisions.
- Any drift between committed IaC and actual infrastructure (`tofu plan`).
- Alert and queue health, if reachable.
- The single most important thing to do next, and why.

Keep it to what someone needs to make a decision. No padding.
