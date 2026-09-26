---
description: Run independent QA verification against a phase's exit criteria
argument-hint: <phase number, e.g. D4>
---

Act as the `qa-verifier` subagent. Independently verify phase **$ARGUMENTS**.

Do not trust the phase's own verification report. Check the system itself.

1. List the exit criteria from `deploy/phases/PHASE_$ARGUMENTS.md`.
2. For each, run your own check and record the command and real output.
3. Attempt to break every control the phase introduced.
4. Confirm documentation produced by the phase is accurate by following it.
5. Log every defect: ID, severity, reproduction, evidence, impact, root cause, recommendation.
6. Record a clear PASS or FAIL with reasons.

A phase fails if any exit criterion lacks executed evidence.
