# Runbook — BREAK_GLASS

> **Status:** Written in Phase D1 (2026-10-02). **Not yet executed.** It is not complete until a drill has been run by following it literally and the "Last executed" table has a row. Sections that depend on later phases (host SSH in D2, age key in D5, emergency stop in D6) are marked with the phase that makes them real.

Holder: **owner only** (RACI.md, decided 2026-09-28). Accepted single point of failure: if the owner and the sealed kit are both unavailable, there is no break-glass.

## When to use this
Use break-glass **only** when all three are true:
1. Something is causing or about to cause harm: a send or publish that must be stopped; a credential that is leaking; the site defaced; an unknown actor in an account.
2. The normal path has failed: the console is unreachable (Cloudflare Access down or locked out), **or** the owner's daily login for a provider is lost (MFA device lost, account locked).
3. Waiting for the normal path to recover would make the harm worse.

Do **not** use it for convenience: a slow deploy, a forgotten password that the normal reset flow can fix, or bypassing a PR review.

## The sealed kit
Prepared once in D1 (runbook `D1_ACCOUNT_SETUP.md` §6), held offline, separate from daily devices.

| Item | Contents | Created in |
|---|---|---|
| K1 | GitHub recovery codes for `saqibtechnn` | D1 |
| K2 | OCI tenancy admin MFA recovery: second registered TOTP device or recovery path documented by Oracle for the tenancy | D1 |
| K3 | Cloudflare 2FA backup codes (only if Cloudflare hosts DNS) | D1 |
| K4 | Vercel recovery codes (if Vercel MFA enabled) | D1 |
| K5 | Sealed copy of the production age key | D5 |
| K6 | Host and console access when Bastion is unavailable: OCI instance console connection procedure (serial console via OCI login + MFA; no standing SSH key). Normal console path is an OCI Bastion session (DECISIONS #25) | D2 |
| K7 | Owner release-signing key backup | D6 |

Storage: printed, in a sealed tamper-evident envelope, with the seal number written in `DEPLOY_LOG.md`. A broken seal = the kit was used.

## Preconditions
- [ ] The trigger conditions above are met. Write down which one, now, with the time.
- [ ] You are the owner (only holder). Nobody else opens the kit.
- [ ] You have a device you trust (not a shared computer).

## Abort criteria
- The normal path starts working again → stop, use it, reseal what you have not opened.
- You cannot tell whether the harm is real (e.g. an alert you cannot confirm) → pull the emergency stop (`EMERGENCY_STOP.md`) instead; stopping is always safe, break-glass is not.

## Procedure

### Step 0 — Stop outbound first, whatever else is wrong
1. If any outbound or publish might be happening: run the emergency stop per `EMERGENCY_STOP.md` (D6). It must work without the console.
   - **Expected result:** queues paused, dispatcher refusing.
   - **If it differs:** go to Step 3 and revoke the dispatcher's credentials at the provider — that stops publishing no matter what the host does.

### Step 1 — Record the start
2. Note in a paper or phone note: time, trigger, envelope seal number. You will copy it into `DEPLOY_LOG.md` afterwards.

### Step 2 — Regain the account you lost
3. Open the envelope. Use only the item for the account you lost.
   - GitHub: github.com/login → *Use a recovery code* → K1. Then *Settings → Password and authentication*: register a new MFA device; **regenerate recovery codes** (old ones are now spent).
   - OCI: sign in to the tenancy, follow K2. Re-register MFA for the admin user.
   - Cloudflare: sign in → *Use backup code* → K3. Re-register 2FA, regenerate backup codes.
   - **Expected result:** signed in, new MFA registered, new recovery codes shown.
   - **If it differs:** use the provider's account-recovery support process; do not create a new account to "get around" it.

### Step 3 — Cut the attacker or the runaway component off at the provider
4. Revoke what is compromised, using the revocation column of `deploy/docs/TOKEN_INVENTORY.md`. Order: whatever can publish or send first (#1 GitHub App key / uninstall), then infrastructure (#10a, #7a), then data (#4, #10b, #11).
   - **Expected result:** each revoked credential returns 401/NotAuthenticated on its next use.
   - **If it differs:** block the identity at the next level up (uninstall the App, block the OCI user, delete the tunnel).
5. Site defaced or a bad merge to `main`: revert via a PR on `saqibtechnn/vsoftsol-website` and merge with the admin bypass (the ruleset permits bypass **only through a PR**). Vercel redeploys `main`. If speed matters more: Vercel → project → *Deployments* → previous good deployment → *Instant Rollback*.
6. Console unreachable (D2+): first try a new Bastion session (sessions expire after 3 h). If the Bastion service itself is down, use K6 (instance console connection). Never add a public inbound rule to get in.

### Step 4 — Stabilise
7. Rotate every credential the incident might have touched, not only the one you know about.
8. Leave the emergency stop engaged. Restart only per `EMERGENCY_STOP.md` restart section (owner A/R).

## Verification
- [ ] Each account you recovered: sign out and sign in again with the **new** MFA device.
- [ ] Each revoked credential: the scope script for it in `deploy/scripts/d1/` now fails at its first in-scope check (proves the old credential is dead).
- [ ] GitHub security log shows the recovery-code sign-in; OCI Audit shows the admin sign-in; Cloudflare audit log shows the 2FA recovery. This is how break-glass use is **detected** — a use that does not appear in these logs means the logs are broken: treat as a second incident.

## Rollback / recovery
Break-glass actions are revocations and recoveries; they are not rolled back. Credentials revoked in error are re-issued through the normal creation path and re-verified with the D1 scope scripts.

## Post-procedure (within 24 h)
- [ ] Record in `deploy/verification/DEPLOY_LOG.md`: time, trigger, items used, seal number, actions, credentials rotated.
- [ ] Replace every item used (new recovery codes printed) and reseal with a **new** numbered envelope; log the new seal number.
- [ ] Review within 7 days: was break-glass actually needed? What failed on the normal path? Fix that, and note it here.
- [ ] Monthly access review (RACI) checks provider logs for recovery-code use with no matching `DEPLOY_LOG.md` entry. An unexplained one = assume the kit is compromised: rotate everything, re-issue the kit.
- [ ] Notify: owner is the only party. If customer data may have been exposed, follow `INCIDENT_RESPONSE.md` (notification duties under PIPEDA).

## Drill (required before the D1 gate can PASS)
Once K1–K3 exist: on a quiet day, sign in to GitHub with one recovery code from a private browser window, confirm the event appears in the security log, regenerate codes, reprint, reseal. Record below. This proves step 3 and the detection path without touching production.

## Last executed
| Date | By | Outcome | Runbook corrections made |
|---|---|---|---|
