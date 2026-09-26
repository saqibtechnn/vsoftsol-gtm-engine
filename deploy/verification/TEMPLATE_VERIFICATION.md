# Phase D<n> Verification Report

**Phase:** D<n> — <title>
**Executed by:** <agent / person>
**Date:** <YYYY-MM-DD>
**Environment(s):** <dev / staging / production>
**Result:** <PASS / PASS WITH CONDITIONS / FAIL>

---

## 1. What was built
<Concrete list of what now exists that did not before. Files, resources, pipelines, configuration.>

## 2. What was deliberately NOT built
<Scope consciously excluded, and why. Anything deferred, with the phase it moves to.>

## 3. Decisions made
| Decision | Options considered | Chosen | Rationale | Reversible? |
|---|---|---|---|---|

## 4. Verification performed
For each exit criterion in the phase file:

### Criterion: <text>
- **Command(s) run:**
```
<exact command>
```
- **Output (secrets redacted):**
```
<real output>
```
- **Result:** PASS / FAIL
- **Notes:**

## 5. Adversarial / negative tests
<What you tried to break, how, and what happened. Every control the phase introduced should appear here.>

## 6. Defects found
| ID | Severity | Description | Status | Fix / accepted risk |
|---|---|---|---|---|

## 7. Known limitations
<What this phase does not cover that someone might assume it does.>

## 8. Residual risks
| Risk | Likelihood | Impact | Mitigation | Accepted by |
|---|---|---|---|---|

## 9. Documentation produced or updated
<Runbooks, docs, diagrams. Confirm each was checked for accuracy by following it.>

## 10. Rollback path
<How to undo this phase if it turns out to be wrong.>

## 11. Recommendation to the gate
<PASS / PASS WITH CONDITIONS (list) / FAIL (reasons). Plus: anything the owner must decide before the next phase.>
