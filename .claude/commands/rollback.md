---
description: Roll the production deployment back to the previous release
---

Execute the rollback runbook at `deploy/runbooks/ROLLBACK.md`.

1. State the current release and the target release (version and image digest).
2. Confirm schema compatibility between the two. If the last deploy included a contracting migration, **stop** — this needs a data-level decision, not a rollback.
3. Present the exact commands you are about to run and **wait for confirmation**.
4. Execute, then run the production smoke suite.
5. Confirm health, readiness and queue state.
6. Append the outcome to `deploy/verification/DEPLOY_LOG.md`.
7. Write a short incident note: what triggered the rollback, impact, and the follow-up needed.
