# Runbook — D1 Account & Identity Setup (owner-executed)

> **Status:** Written in Phase D1 (2026-10-02), rewritten step by step 2026-10-07. The **owner** executes it. Claude Code may not create accounts, sign in, or handle passwords, MFA secrets or private keys.
> These steps are console clicks because enrolling MFA and creating the first machine identities needs a human admin login. Everything after that is scripted (`deploy/scripts/d1/`).

**Time:** about 1.5–2 hours. Do the parts in order. Each one ends with what to send Claude Code.

## Ground rules (read once)
1. **Never paste** a password, recovery code, private key (`.pem`) or token into the Claude chat, an issue, a commit or a screenshot you share. IDs, check-script output and screenshots of settings pages are fine.
2. **USD 0 rule:** if any screen asks for a card or offers a paid upgrade to continue, **stop** and tell Claude Code what the screen says.
3. **Screenshots:** keep them in a private folder on your PC (e.g. `Documents\VGE-evidence\D1`). Do **not** put them in the repo; it is public.
4. If a screen looks different from what is described here (providers rename menus), look for the same words. If you cannot find it, stop and describe what you see.
5. Keep a notepad open for the **non-secret IDs** you will be asked for: App IDs, Cloudflare Account/Zone ID, OCI OCIDs, envelope numbers.

---

## Part A — Prove nobody can push straight to `main` (5 min, on this PC)

1. Press **Start**, type **Git Bash**, open it.
2. Go to the project:
   ```bash
   cd "/e/Claoud Projects/vsoftsol-Marketing Agent/.claude/worktrees/happy-kilby-895c1c"
   ```
3. Run the website test:
   ```bash
   deploy/scripts/d1/verify_site_push_blocked.sh saqibtechnn/vsoftsol-website --confirm
   ```
   - **Expected:** a list of rules, a `git push` attempt that is refused (text such as `GH013: Repository rule violations`), and the last line `RESULT: PASS`.
   - **If the last line is `RESULT: FAIL - direct push was ACCEPTED`:** stop and tell Claude Code immediately. The pushed commit is empty, so the website does not change, but it must be reverted.
   - **If it says `ERROR: rule ... is not active`:** the ruleset was removed; tell Claude Code.
4. Run the VGE repo test:
   ```bash
   deploy/scripts/d1/verify_site_push_blocked.sh saqibtechnn/vsoftsol-gtm-engine --confirm
   ```
   Same expected result.

**Send Claude Code:** the full output of both commands (in Git Bash, select the text with the mouse, then right-click → Copy).

---

## Part B — GitHub (25 min)

### B1. Two-factor authentication and recovery codes
1. github.com → your avatar (top right) → **Settings** → left menu **Password and authentication**.
2. Under *Two-factor authentication*: it must say **Enabled**, with an **Authenticator app** or **Security key** listed. SMS alone is not enough: if only SMS is listed, click **Add** next to Authenticator app and follow the QR-code steps.
3. Screenshot this section → `B1-github-2fa.png`.
4. Same page, **Recovery options → Recovery codes → View** → **Download**, then print the file. Delete the downloaded file and empty the Recycle Bin. The printout goes in the envelope (Part G).

### B2. Commit signing key (makes your future commits show "Verified")
1. In Git Bash:
   ```bash
   ssh-keygen -t ed25519 -C "github-signing" -f ~/.ssh/github_signing
   ```
   Press Enter twice (or set a passphrase).
2. Show the **public** key and copy it:
   ```bash
   cat ~/.ssh/github_signing.pub
   ```
3. GitHub → Settings → **SSH and GPG keys** → **New SSH key**. Title `signing`, **Key type: Signing Key**, paste, **Add SSH key**.
4. Tell git to sign your commits with it:
   ```bash
   git config --global gpg.format ssh
   ```
   ```bash
   git config --global user.signingkey ~/.ssh/github_signing.pub
   ```
   ```bash
   git config --global commit.gpgsign true
   ```
   - **Expected:** your next commit on GitHub shows a green **Verified** badge.

### B3. Create the website bot App `vge-site-bot`
1. GitHub → Settings → (bottom of the left menu) **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. Fill in:
   - **GitHub App name:** `vge-site-bot` (if taken, use `vge-site-bot-vsoftsol` and tell Claude Code)
   - **Homepage URL:** `https://vsoftsol.com`
   - **Callback URL:** leave empty. Untick *Request user authorization (OAuth) during installation* if ticked.
   - **Webhook:** **untick "Active"**.
3. **Permissions → Repository permissions:**
   - **Contents:** Read and write
   - **Pull requests:** Read and write
   - **Metadata:** Read-only (set automatically)
   - Everything else: **No access**
   - **Organization permissions** and **Account permissions:** all **No access**.
4. **Where can this GitHub App be installed?** → **Only on this account** → **Create GitHub App**.
5. On the App page that opens:
   - Note the **App ID** (a number near the top) → notepad as `GH_SITE_APP_ID`.
   - Scroll to **Private keys** → **Generate a private key**. A `.pem` file downloads. Keep it for B5.
   - Screenshot the *Permissions & events* tab → `B3-site-bot-permissions.png`.
6. Left menu **Install App** → **Install** next to your account → **Only select repositories** → pick **vsoftsol-website** only → **Install**.
   - Screenshot the installation page showing that one repository → `B3-site-bot-install.png`.

### B4. Create the read-only App `vge-repo-reader`
Repeat B3 with these differences:
- Name `vge-repo-reader`, homepage `https://vsoftsol.com`, webhook **not active**.
- Repository permissions: **Contents: Read-only**. Metadata read-only (automatic). **Everything else No access** (no Pull requests).
- Only on this account.
- App ID → notepad as `GH_READER_APP_ID`. Generate a private key (second `.pem`).
- Install App → **Only select repositories** → select exactly: `agentic-enhancement-platform`, `vsoftsol-syslog-manager`, `VsoftNetwork-Monitoring`, `vSoft-Baclup-Updates`.
- Screenshots `B4-reader-permissions.png`, `B4-reader-install.png`.

### B5. Store the keys and IDs as Codespaces secrets, then delete the key files
1. GitHub → Settings → left menu **Codespaces** → *Codespaces secrets* → **New secret**.
2. **Name** `GH_APP_KEY_PEM`. **Value:** open the **site-bot** `.pem` in Notepad, Ctrl+A, Ctrl+C, paste. **Repository access:** `saqibtechnn/vsoftsol-gtm-engine` only. **Add secret**.
3. **Name** `GH_READER_APP_KEY_PEM`, value = the **reader** `.pem`, same single repository.
4. Add the two App IDs the same way (they are not secret; this just saves typing later): `GH_SITE_APP_ID`, `GH_READER_APP_ID`.
5. Delete both `.pem` files from Downloads and empty the Recycle Bin. If a key is ever lost, generate a new one on the App page; nothing breaks.

**Send Claude Code:** "B done", the two App IDs, and the App names if they differ.

---

## Part C — Oracle Cloud (30 min)

Sign in at cloud.oracle.com with your tenancy name.

### C1. Confirm region and no card
1. Top-right **Profile** icon → **Tenancy: <name>**. Check **Home region: Canada Southeast (Toronto)** → screenshot `C1-tenancy.png`. Copy the tenancy **OCID** (click *Copy*) → notepad as `OCI_TENANCY_OCID`.
   - **If the home region is not Toronto: stop** and tell Claude Code (Always Free only exists in the home region).
2. ☰ menu → **Billing & Cost Management** → **Payment method** (or *Upgrade and Manage Payment*). It should show **no** payment method / *Free Tier*. Screenshot `C1-billing.png`. **Do not click Upgrade.**

### C2. MFA
1. Profile icon → **My profile** → **Security** (or *Multifactor authentication*). It must show an enrolled **mobile app (TOTP)** or security key. If not: **Enable multifactor authentication** and follow the QR steps.
2. Enforce it for everyone: ☰ → **Identity & Security** → **Domains** → **Default** → **Security** → **MFA**: make sure your factor type is allowed. Then **Sign-on policies** → *Default Sign-On Policy*: the rule for console access must **require MFA**. Save.
3. Recovery: on *My profile → Security*, **generate bypass codes** if offered and print them for the envelope. If bypass codes are not offered, enrol a **second** authenticator device instead.
4. Screenshot the MFA status → `C2-mfa.png`.

### C3. Budget alert at USD 0.01
1. ☰ → **Billing & Cost Management** → **Budgets** → **Create budget**.
2. **Name** `vge-zero`; **Target:** the root compartment (your tenancy); **Schedule:** monthly; **Budget amount:** `1` (USD).
3. **Budget alert rule:** *Actual spend*, **Threshold metric: Percentage of budget**, **Threshold: 1** (= USD 0.01), **Email recipients:** your email → **Create**.
4. Screenshot → `C3-budget.png`.
   - **If Budgets is missing or asks for an upgrade: stop** and tell Claude Code.

### C4. Audit log retention
☰ → **Observability & Management → Audit** (or Governance → Tenancy details → Audit retention): retention should be **365 days**. Screenshot `C4-audit.png`.

### C5. Compartment, group, machine user, policy
1. ☰ → **Identity & Security** → **Compartments** → **Create compartment**: name `vge`, description `VGE production`, parent = root. Open it and copy its **OCID** → notepad as `OCI_VGE_COMPARTMENT`.
2. ☰ → Identity & Security → **Domains** → **Default** → **Groups** → **Create group**: `vge-provisioners`.
3. Same domain → **Users** → **Create user**: name `vge-tofu`. If a unique email is required, use your own address with a tag (e.g. `saqibtechnn+vgetofu@gmail.com`). Add to group `vge-provisioners`. Create.
4. Open `vge-tofu` → **Edit user capabilities**: tick **API keys** only. **Untick** Local password, SMTP credentials, Customer secret keys, Auth tokens, OAuth 2.0 credentials, DB credentials. Save. Do **not** set a password for this user.
5. ☰ → Identity & Security → **Policies** → compartment **(root)** → **Create policy**: name `vge-provisioners-policy`, **Show manual editor**, paste exactly:
   ```
   Allow group vge-provisioners to manage all-resources in compartment vge where request.permission != 'BASTION_SESSION_CREATE'
   ```
   **Create**.
   - **If Oracle rejects the statement: stop** and send Claude Code the exact error. Do not delete the `where` part.
6. Add `OCI_TENANCY_OCID` and `OCI_VGE_COMPARTMENT` as Codespaces secrets (GitHub → Settings → Codespaces → New secret, repository `vsoftsol-gtm-engine` only). OCIDs are identifiers, not secrets; this saves typing.
7. The user's API key is added in Part F.

**Send Claude Code:** "C done", and anything that differed (especially C3 or C5.5).

---

## Part D — Cloudflare (15 min)

1. dash.cloudflare.com → Profile icon → **My Profile** → **Authentication**: **Two-Factor Authentication** must be on with an authenticator app. If not, enable it. **Backup codes:** view or regenerate them, print for the envelope. Screenshot `D1-2fa.png`.
2. Account level → **Manage Account → Members**: only you should be listed. If there is an option to **enforce two-factor authentication** for members, turn it on. Screenshot `D2-members.png`.
3. **Manage Account → Account API Tokens** → **Create Token** → **Create Custom Token**:
   - **Name:** `vge-tofu-dns`
   - **Permissions:** one row only: **Zone** · **DNS** · **Edit**
   - **Zone Resources:** **Include** · **Specific zone** · `vsoftsol.com`
   - **Client IP Address Filtering:** leave empty
   - **TTL:** start today, end **90 days** from today
   - **Continue to summary** → check it lists only `vsoftsol.com - DNS:Edit` → **Create Token**.
   - **If "Account API Tokens" does not exist**, use My Profile → **API Tokens** → Create Custom Token with the same settings, and tell Claude Code (that token is tied to your user rather than the account).
4. The token is shown **once**. Copy it straight into GitHub → Settings → Codespaces → **New secret**: name `CF_API_TOKEN`, repository `vsoftsol-gtm-engine` only. Do not save it anywhere else.
5. Open the **vsoftsol.com** domain → **Overview**, right column *API*: copy **Zone ID** and **Account ID**. Add both as Codespaces secrets: `CF_ZONE_ID`, `CF_ACCOUNT_ID` (same repository).

**Send Claude Code:** "D done", and whether you used Account API Tokens or user API Tokens.

---

## Part E — Vercel (5 min)

1. vercel.com → avatar → **Account Settings** → **Authentication** (or *Security*): enable **Two-Factor Authentication** with an authenticator app. Print the **recovery codes** for the envelope.
2. Screenshot → `E1-vercel-2fa.png`.
3. Nothing else changes in Vercel now. (Hobby-plan terms are a separate decision: DECISIONS #26.)

---

## Part F — Run all checks in a Codespace (20 min)

### F1. Open the Codespace
1. github.com/saqibtechnn/vsoftsol-gtm-engine → **Code** (green button) → **Codespaces** tab → **⋯** → **New with options** → **Branch:** `claude/happy-kilby-895c1c`, **Machine type:** 2-core → **Create codespace**.
   - A browser VS Code opens. The terminal is at the bottom (if not: ☰ → Terminal → New Terminal).
   - Secrets from B5, C5.6 and D appear as environment variables. **If you added a secret after the Codespace was created, stop and restart the Codespace** (github.com/codespaces → ⋯ → Stop, then open it again).
2. Check the secrets arrived (prints names only, never values):
   ```bash
   env | cut -d= -f1 | grep -E '^(GH_|CF_|OCI_)' | sort
   ```
   - **Expected:** `CF_ACCOUNT_ID`, `CF_API_TOKEN`, `CF_ZONE_ID`, `GH_APP_KEY_PEM`, `GH_READER_APP_ID`, `GH_READER_APP_KEY_PEM`, `GH_SITE_APP_ID`, `OCI_TENANCY_OCID`, `OCI_VGE_COMPARTMENT`.

### F2. Create the Oracle API key for `vge-tofu`
1. In the Codespace terminal:
   ```bash
   mkdir -p ~/.oci && chmod 700 ~/.oci && openssl genrsa -out ~/.oci/vge-tofu.pem 2048 && chmod 600 ~/.oci/vge-tofu.pem && openssl rsa -in ~/.oci/vge-tofu.pem -pubout
   ```
   It prints a **public** key (`-----BEGIN PUBLIC KEY-----` … `-----END PUBLIC KEY-----`). Copy all of it. The private key never leaves the Codespace.
2. Oracle console → Domains → Default → Users → `vge-tofu` → **API keys** → **Add API key** → **Paste a public key** → paste → **Add**.
3. Oracle shows a **Configuration file preview**. Copy it. In the Codespace:
   ```bash
   code ~/.oci/config
   ```
   Paste the preview. Change the first line from `[DEFAULT]` to `[VGE_TOFU]` and set the `key_file` line to `key_file=~/.oci/vge-tofu.pem`. Save (Ctrl+S). Then:
   ```bash
   chmod 600 ~/.oci/config
   ```
4. Install the Oracle command-line tool and check jq:
   ```bash
   pip install --quiet oci-cli && oci --version && jq --version
   ```
5. Test that the key works:
   ```bash
   oci --profile VGE_TOFU os ns get
   ```
   - **Expected:** `{"data": "<namespace>"}`. If `NotAuthenticated`: the fingerprint or user OCID in `~/.oci/config` does not match; re-copy the preview.

### F3. Revocation tests (one per credential type)
These prove each type of credential stops working the moment it is deleted.
1. **Oracle key:**
   ```bash
   openssl genrsa -out /tmp/throwaway.pem 2048 && openssl rsa -in /tmp/throwaway.pem -pubout
   ```
   Add that public key to `vge-tofu` (as F2.2). Add a second section to `~/.oci/config` named `[THROWAWAY]`, a copy of `[VGE_TOFU]` with the new `fingerprint` and `key_file=/tmp/throwaway.pem`. Then:
   ```bash
   oci --profile THROWAWAY os ns get
   ```
   It works. **Delete that API key in the console**, wait 1 minute, run the same command again: it must fail with `NotAuthenticated`. Copy both outputs, then remove the profile section and the file:
   ```bash
   rm /tmp/throwaway.pem
   ```
2. **GitHub App key:** on the `vge-site-bot` page, **Generate a private key** again (a second key), then immediately **delete it** (trash icon next to it). Delete the downloaded file. Screenshot the *Private keys* list showing only one key → `F3-app-key-revoked.png`. (Installation-token revocation is tested automatically in F4.)
3. **Cloudflare token:** create a throwaway custom token with the same DNS-edit permission and copy it. In the Codespace (the space before `read` keeps it out of shell history):
   ```bash
    read -rsp "token: " T; echo; curl -s -H "Authorization: Bearer $T" https://api.cloudflare.com/client/v4/user/tokens/verify | jq .success
   ```
   Paste the token at the prompt (it is not shown) → `true`. Delete the throwaway token in Cloudflare, run the same line again with the same token → `false`. Paste only the `true`/`false` lines to Claude Code.

### F4. Run every scope check
```bash
deploy/scripts/d1/run_all_checks.sh 2>&1 | tee /tmp/d1-checks.txt
```
- **Expected summary:** `1 vge-site-bot PASS`, `15 vge-repo-reader PASS`, `7a vge-tofu-dns PASS`, and `10a vge-tofu FAIL` **only** because its check 7 says `NOT RUN` (the bastion does not exist until D2). Every other line inside 10a must be `PASS`.
- Any other `FAIL`: do not widen or narrow permissions to make it pass. Send the output.

**Send Claude Code:** all of `/tmp/d1-checks.txt` (open it with `code /tmp/d1-checks.txt`, Ctrl+A, Ctrl+C) and the F3 results.

Afterwards stop the Codespace to save your free hours: github.com/codespaces → **⋯** → **Stop codespace**.

---

## Part G — Break-glass envelope and drill (15 min)

1. Gather the printouts: GitHub recovery codes (B1), Oracle bypass codes or second-device note (C2), Cloudflare backup codes (D1), Vercel recovery codes (E1).
2. Put them in an envelope, seal it, sign across the seal, and write a number on it (e.g. `VGE-BG-001`). Store it offline and away from your laptop.
3. **Drill** (proves the envelope works and that its use is visible):
   1. Open a **private/incognito** browser window → github.com/login → username and password → on the 2FA screen choose **Use a recovery code** → open the envelope and use **one** code.
   2. In your normal window: Settings → **Security log**. Find the sign-in from the drill. Screenshot `G3-security-log.png`.
   3. Settings → Password and authentication → Recovery codes → **Regenerate**. Print the new ones; destroy the old printout.
   4. Reseal everything in a **new** envelope with a new number (`VGE-BG-002`).

**Send Claude Code:** both envelope numbers and "drill done, sign-in visible in security log" (or what you saw instead).

---

## After all parts
Claude Code pastes the outputs into `PHASE_D1_VERIFICATION.md`, moves TOKEN_INVENTORY rows to VERIFIED, logs the envelope in `DEPLOY_LOG.md`, and recommends a gate result. Then you:
1. Edit `deploy/verification/DEPLOY_GATES.md` row D1 yourself (status, your name, date).
2. **Squash-merge** PR #1 on GitHub: Merge button → arrow → *Squash and merge*, ticking the bypass box (there is no second reviewer).

## Last executed
| Date | By | Outcome | Runbook corrections made |
|---|---|---|---|
