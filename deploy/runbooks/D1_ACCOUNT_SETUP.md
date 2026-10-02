# Runbook — D1 Account & Identity Setup (owner-executed)

> **Status:** Written in Phase D1 (2026-10-02). Owner executes; Claude Code may not create accounts, sign in, or handle passwords, MFA secrets or private keys.
> These steps are console clicks because account creation, MFA enrolment and initial admin actions cannot be automated without first holding an admin credential. Everything after the first machine identity exists is scripted.

Budget rule (DECISIONS #23): if any screen asks for a payment method, **stop** and record it. Exception only where the owner has chosen it in writing (Cloudflare, see §3).

Evidence rule: for each step, save the evidence listed (screenshot or command output) into `deploy/verification/evidence/d1/` (gitignored if it contains identifiers you do not want committed; redact account IDs/emails before committing).

## Preconditions
- [ ] Owner at a trusted device with an authenticator app.
- [ ] GitHub Codespace for the VGE repo available (for §2.4 and the scripts). **Blocked until the VGE repo exists on GitHub (OPEN A2).**

## §1 GitHub
1. *Settings → Password and authentication*: two-factor authentication **enabled**, with an authenticator app or security key (not SMS only). **Evidence:** screenshot of the 2FA section showing "Enabled".
2. Same page → *Recovery codes* → **Download**, print, put in the break-glass envelope (BREAK_GLASS K1). Delete the downloaded file.
3. *Settings → SSH and GPG keys* → add an **SSH signing key** (*Key type: Signing Key*). Locally, in the place you make commits (Codespaces):
   ```bash
   git config --global gpg.format ssh
   ```
   ```bash
   git config --global user.signingkey ~/.ssh/id_ed25519.pub
   ```
   ```bash
   git config --global commit.gpgsign true
   ```
   **Evidence:** a commit on GitHub shows **Verified**.
4. Create the GitHub App (*Settings → Developer settings → GitHub Apps → New GitHub App*):
   - Name `vge-site-bot`; Homepage `https://vsoftsol.com`; **Webhook: Active unchecked**.
   - Repository permissions: **Contents: Read and write**, **Pull requests: Read and write**. Everything else **No access**. Account permissions: all **No access**.
   - *Where can this GitHub App be installed?* **Only on this account**.
   - Create → *Generate a private key* → the `.pem` downloads. Store it as a Codespaces secret `GH_APP_KEY_PEM` restricted to the VGE repo, then **delete the downloaded file**. Do not paste it into chat.
   - *Install App* → `saqibtechnn` → **Only select repositories** → `vsoftsol-website`.
   - **Evidence:** screenshot of the permissions page and the installation's repository list. Record the App ID (not secret) in TOKEN_INVENTORY #1.
5. Revocation test (throwaway): generate a **second** private key, mint a JWT with it (same method as `verify_github_app_scope.sh`), **delete** that key in the App settings, confirm the JWT is rejected with 401. **Evidence:** the 401 output.
6. Apply the site ruleset — Claude Code may run this **only after the owner confirms in chat**:
   ```bash
   deploy/scripts/d1/apply_site_ruleset.sh saqibtechnn/vsoftsol-website
   ```
   (dry run; then the same with `--apply`).

## §2 Oracle Cloud (OCI)
1. Tenancy exists, home region **Canada Southeast (Toronto) `ca-toronto-1`**, account type **Free Tier / Always Free**, *Billing → Payment method*: **none**. **Evidence:** screenshot of *Tenancy details* (home region) and of the payment-method page. If the tenancy's home region is anything else, **stop** — Always Free resources exist only in the home region (DECISIONS #1) and it cannot be changed.
2. *Profile → My profile → Security*: **enable MFA** (TOTP) for the admin user. Identity domain → *Settings → Security → MFA*: enforce MFA for all users with console access. Register a **second** TOTP device or record the recovery method as BREAK_GLASS K2. **Evidence:** screenshot showing MFA enabled and enforcement policy.
3. Budget alert at the ceiling: *Billing & Cost Management → Budgets → Create budget*: scope **tenancy (root compartment)**, monthly amount **USD 1** (the smallest whole amount), alert rule **Actual spend > 1% (USD 0.01)**, recipients: owner email. **Evidence:** screenshot of the budget and alert rule. If Budgets is not offered on the Always-Free-only tenancy, **stop and report** — this is a provider difference from DECISIONS #23.
4. Audit: *Observability → Audit*: confirm retention (default 365 days). **Evidence:** screenshot.
5. Compartment `vge` under root. Then IAM (Identity domain *Default*):
   - Group `vge-provisioners`; user `vge-tofu` (**no** console password: uncheck *Local password* / don't set one; capabilities: **API keys only**). Add to group.
   - Policy `vge-provisioners-policy` in **root**: `Allow group vge-provisioners to manage all-resources in compartment vge where request.permission != 'BASTION_SESSION_CREATE'` (DECISIONS #25: provisioning may build the bastion but not open sessions). If the console rejects this condition syntax, **stop and report** — do not drop the condition
   - API key for `vge-tofu`: generate **in Codespaces** (`openssl genrsa -out ~/.oci/vge-tofu.pem 2048`; public key uploaded in the console). Private key stays in the Codespaces secret store; never leaves it.
   - **Evidence:** `oci iam user get` output for `vge-tofu` showing `capabilities` (API keys true, console password false).
6. Revocation test: add a second throwaway API key to `vge-tofu`, run `oci os ns get` with it (works), delete the key, run again (expect `NotAuthenticated`). **Evidence:** both outputs.
7. Scope test:
   ```bash
   OCI_IDENTITY=vge-tofu deploy/scripts/d1/verify_oci_scope.sh
   ```
   (with the env vars listed in the script header).

## §3 Cloudflare — only if vsoftsol.com DNS is on Cloudflare (OPEN A6); no Zero Trust, no tunnel (DECISIONS #25)
Once decided:
1. Account → *Members*: only the owner; **Enforce two-factor authentication** for members. Owner 2FA on; backup codes → BREAK_GLASS K3. **Evidence:** screenshots.
2. If vsoftsol.com DNS is (or is moved to) Cloudflare — **a DNS change requires separate explicit confirmation** (CLAUDE.md §2.7).
3. Account-owned token `vge-tofu-dns` (*Manage Account → Account API Tokens → Create*): Zone·DNS·Edit only (zone: vsoftsol.com only); TTL 90 days. Store as a Codespaces secret. Run `verify_cloudflare_token_scope.sh`. Revocation test with a throwaway token of the same permissions.
4. No Zero Trust organisation, Access application or tunnel is created (DECISIONS #25). Console access is OCI Bastion, built in D2.

## §4 Git identity on the owner PC / Codespaces
No git identity is configured on the owner PC by Claude. The owner sets `user.name` / `user.email` and the signing key (§1.3) where commits are made.

## §5 Vercel
1. Account MFA on; recovery codes → BREAK_GLASS K4. **Evidence:** screenshot.
2. Record the plan (Hobby/Pro) in IDENTITY_AND_ACCESS A8. Hobby is limited to non-commercial use under Vercel's terms; vsoftsol.com is commercial → owner decision.
3. No Vercel token is created unless D6/D9 shows the PR commit status is insufficient (TOKEN_INVENTORY #2).

## §6 Break-glass kit
Assemble K1–K4 into one sealed, numbered envelope; write the seal number in `deploy/verification/DEPLOY_LOG.md`. Then run the drill in `BREAK_GLASS.md`.

## Verification
- [ ] Every evidence item above saved.
- [ ] Every scope script exits 0; output pasted (redacted) into `PHASE_D1_VERIFICATION.md`.
- [ ] TOKEN_INVENTORY rows moved from DESIGNED to VERIFIED with dates.

## Last executed
| Date | By | Outcome | Runbook corrections made |
|---|---|---|---|
