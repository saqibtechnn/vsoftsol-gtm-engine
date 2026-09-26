# Runbook — RESTORE

> **Status: TEMPLATE.** Written during the phase that owns it. Do not treat as complete until that phase's gate has passed and this runbook has been executed end to end by someone following it literally.

## When to use this
<Trigger conditions. Be specific — a runbook you have to interpret is a runbook you will misuse at 2am.>

## Preconditions
- [ ] <What must be true before starting>
- [ ] <Access / credentials required, and where they live>
- [ ] <Who must be informed or present>

## Abort criteria
<What conditions mean: stop, do not continue, escalate instead.>

## Procedure
1. <Step. One action per step. Include the exact command.>
   - **Expected result:** <what you should see>
   - **If it differs:** <what to do>

## Verification
- [ ] <How you know it actually worked — a positive check, not an absence of errors>

## Rollback / recovery
<How to undo this procedure if it goes wrong midway.>

## Post-procedure
- [ ] Record the outcome in `deploy/verification/DEPLOY_LOG.md`
- [ ] Note any step where this runbook was wrong or unclear, and fix it now
- [ ] Notify: <who>

## Last executed
| Date | By | Outcome | Runbook corrections made |
|---|---|---|---|
