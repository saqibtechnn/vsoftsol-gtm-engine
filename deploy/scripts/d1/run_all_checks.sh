#!/usr/bin/env bash
# Runs every D1 scope check that can run before D2, in a GitHub Codespace, and prints one summary.
# Inputs come from Codespaces secrets (exposed as env vars) plus four non-secret IDs set below
# or exported beforehand. Private keys are written to a private temp dir and deleted on exit.
#
# Usage (in a Codespace on this repo):  deploy/scripts/d1/run_all_checks.sh 2>&1 | tee /tmp/d1-checks.txt
# Then paste /tmp/d1-checks.txt to Claude Code. It contains no secrets (every script redacts).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }

# --- Non-secret identifiers (owner fills these in, or exports them before running) -------------
: "${GH_SITE_APP_ID:=}"          # vge-site-bot App ID (number on the App settings page)
: "${GH_READER_APP_ID:=}"        # vge-repo-reader App ID
: "${CF_ACCOUNT_ID:=}"           # Cloudflare: domain Overview page, right column
: "${CF_ZONE_ID:=}"              # Cloudflare: same page
: "${OCI_TENANCY_OCID:=}"        # OCI: Profile -> Tenancy -> OCID
: "${OCI_VGE_COMPARTMENT:=}"     # OCI: Identity -> Compartments -> vge -> OCID

# --- Secrets (Codespaces secrets, never typed here) --------------------------------------------
#   GH_APP_KEY_PEM, GH_READER_APP_KEY_PEM, CF_API_TOKEN
# --- OCI: profile VGE_TOFU in ~/.oci/config (D1_ACCOUNT_SETUP step F2)

missing=()
for v in GH_SITE_APP_ID GH_READER_APP_ID CF_ACCOUNT_ID CF_ZONE_ID OCI_TENANCY_OCID OCI_VGE_COMPARTMENT \
         GH_APP_KEY_PEM GH_READER_APP_KEY_PEM CF_API_TOKEN; do
  [[ -n "${!v:-}" ]] || missing+=("$v")
done
[[ ${#missing[@]} -eq 0 ]] || die "not set: ${missing[*]}  (see deploy/runbooks/D1_ACCOUNT_SETUP.md part F)"
for c in openssl curl jq oci; do command -v "$c" >/dev/null || die "$c not found (part F, step 3)"; done
grep -q '^\[VGE_TOFU\]' ~/.oci/config 2>/dev/null || die "profile [VGE_TOFU] missing from ~/.oci/config (part F, step 2)"

KEYS="$(mktemp -d)"; chmod 700 "$KEYS"
trap 'rm -rf "$KEYS"' EXIT
printf '%s\n' "$GH_APP_KEY_PEM"        > "$KEYS/site.pem";   chmod 600 "$KEYS/site.pem"
printf '%s\n' "$GH_READER_APP_KEY_PEM" > "$KEYS/reader.pem"; chmod 600 "$KEYS/reader.pem"

declare -A RESULT
section() { echo; echo "################ $1 ################"; }
run() { # name -- command...
  local name=$1; shift 2
  section "$name"
  if "$@"; then RESULT[$name]=PASS; else RESULT[$name]=FAIL; fi
}

echo "D1 checks — $(date -u +%Y-%m-%dT%H:%M:%SZ) — $(git -C "$HERE" rev-parse --short HEAD)"

run "1 vge-site-bot" -- env GH_APP_ROLE=site GH_APP_ID="$GH_SITE_APP_ID" GH_APP_KEY_FILE="$KEYS/site.pem" \
  GH_APP_SITE_REPO=saqibtechnn/vsoftsol-website \
  GH_APP_EXPECT_REPOS=saqibtechnn/vsoftsol-website \
  GH_APP_OTHER_REPO=saqibtechnn/agentic-enhancement-platform \
  "$HERE/verify_github_app_scope.sh"

run "15 vge-repo-reader" -- env GH_APP_ROLE=reader GH_APP_ID="$GH_READER_APP_ID" GH_APP_KEY_FILE="$KEYS/reader.pem" \
  GH_APP_SITE_REPO=saqibtechnn/agentic-enhancement-platform \
  GH_APP_EXPECT_REPOS=saqibtechnn/agentic-enhancement-platform,saqibtechnn/vsoftsol-syslog-manager,saqibtechnn/VsoftNetwork-Monitoring,saqibtechnn/vSoft-Baclup-Updates \
  "$HERE/verify_github_app_scope.sh"

run "7a vge-tofu-dns" -- env CF_API_TOKEN="$CF_API_TOKEN" CF_ACCOUNT_ID="$CF_ACCOUNT_ID" CF_ZONE_ID="$CF_ZONE_ID" \
  "$HERE/verify_cloudflare_token_scope.sh"

# Check 7 (bastion session denial) needs the bastion from D2; it reports NOT RUN and this row FAILs
# until then. That is expected and is carried as a D2 condition.
run "10a vge-tofu" -- env OCI_CLI_PROFILE=VGE_TOFU OCI_IDENTITY=vge-tofu \
  OCI_TENANCY_OCID="$OCI_TENANCY_OCID" OCI_VGE_COMPARTMENT="$OCI_VGE_COMPARTMENT" \
  "$HERE/verify_oci_scope.sh"

section "SUMMARY"
for k in "1 vge-site-bot" "15 vge-repo-reader" "7a vge-tofu-dns" "10a vge-tofu"; do
  printf '%-22s %s\n' "$k" "${RESULT[$k]}"
done
echo "(10a is expected to show FAIL only because check 7 is NOT RUN before D2; every other line in it must PASS)"
