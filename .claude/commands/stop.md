---
description: Emergency stop — halt all queues, schedulers and outbound immediately
---

Execute the emergency stop at `deploy/runbooks/EMERGENCY_STOP.md`.

Priority order:
1. Halt outbound sending first. Nothing else matters as much — a wrong email cannot be recalled.
2. Halt the publishing pipeline.
3. Pause schedulers and drain workers.
4. Confirm each halt with a positive check, not an assumption.
5. Report what was in flight when the stop landed, and what state it was left in.

Do not restart anything until the operator explicitly asks and the cause is understood.
