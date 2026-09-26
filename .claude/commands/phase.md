---
description: Execute a single deployment phase end to end under the standard protocol
argument-hint: <phase number, e.g. D3>
---

Execute deployment phase **$ARGUMENTS**.

1. Confirm the previous phase's gate is signed off in `deploy/verification/DEPLOY_GATES.md`. If it is not, stop and say so.
2. Read `deploy/phases/PHASE_$ARGUMENTS.md` in full, plus `CLAUDE.md`.
3. Follow the standard phase protocol: Plan → Design → Implement → Test → Verify → Report → Gate.
4. Delegate specialist work to the appropriate subagent in `.claude/agents/`.
5. Produce every deliverable listed. No stubs, no TODOs, no deferrals.
6. Run every verification step and capture real output, with secrets redacted.
7. Write `deploy/verification/PHASE_$ARGUMENTS_VERIFICATION.md` from the template.
8. Append the result to `DEPLOY_GATES.md`, commit, tag, and **stop for review**.

If anything in the phase cannot be completed as specified, stop and report — do not substitute a simpler alternative.
