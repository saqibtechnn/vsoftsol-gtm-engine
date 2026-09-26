# Phase D1 — Accounts, Identity & Access Foundations

**Lead subagent:** `security-engineer`
**Prerequisite:** D0 gate signed

## Objective
Establish who and what can touch the system, before there is anything to touch.

## Deliverables
1. Hosting/cloud account with MFA enforced and billing alerts at the D0 ceiling.
2. Separate **service accounts** per integration. No personal accounts anywhere in the system path.
3. GitHub configuration: branch protection on the VGE repo and the vsoftsol.com site repo (required review, no force push, no direct push to main), signed commits, environment protection rules with required reviewers for production.
4. Least-privilege tokens: GitHub App or fine-grained PAT scoped to specific repos only; Vercel token scoped to the one project; social app credentials at minimum scope; Anthropic API key with usage limits.
5. Cloudflare account access policy and Zero Trust group for console access.
6. `deploy/docs/TOKEN_INVENTORY.md` — every credential: name, purpose, scope, owner, storage location, rotation interval, revocation procedure, last rotated.
7. `deploy/runbooks/BREAK_GLASS.md` — emergency access when normal paths fail, and how its use is detected and reviewed afterwards.

## Implementation tasks
- Create each credential at the narrowest scope that works, then test upward only if something genuinely fails.
- Record the revocation command for every credential at the moment you create it.
- Enable audit logging on every provider that offers it.

## Verification
- [ ] For each token, attempt an action **outside** its intended scope and confirm denial. Evidence per token.
- [ ] Confirm a direct push to the site repo's `main` is blocked.
- [ ] Confirm MFA cannot be bypassed on any account in the path.
- [ ] Confirm every credential in the inventory has a revocation path that has been tested.
- [ ] Confirm no personal account holds a role the system depends on.

## Exit gate
Zero credentials with broader scope than documented. Zero shared personal accounts. Tag `deploy-v0.1.0`.
