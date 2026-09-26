---
description: Run a disaster recovery or restore drill and record measured RTO/RPO
argument-hint: <restore | dr | failure-injection>
---

Run the **$ARGUMENTS** drill from `deploy/runbooks/DISASTER_RECOVERY.md`.

Rules:
- Never drill against production data in place. Restore to a fresh target.
- Time every stage. Record the RTO and RPO **actually achieved**, not the target.
- Follow only the written runbook. Every gap, error or assumed step you hit is a defect — log it.
- Verify the restored system works by running the application against it, not by checking the database exists.

Write the results to `deploy/verification/DRILL_<date>.md`, including the gap list and what the runbook needs changed.
