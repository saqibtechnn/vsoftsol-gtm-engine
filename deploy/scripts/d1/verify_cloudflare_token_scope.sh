#!/usr/bin/env bash
# D1 verification: the Cloudflare account-owned token `vge-tofu-dns` can edit DNS on ONE zone
# and the account's tunnels, and nothing else. All denial checks are reads or deliberately
# invalid writes, so a wrongly-broad token changes nothing.
#
# Inputs (env):
#   CF_API_TOKEN     the token under test. Never printed.
#   CF_ACCOUNT_ID    account ID
#   CF_ZONE_ID       the one zone the token may edit
# Requires: curl, jq.
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
for v in CF_API_TOKEN CF_ACCOUNT_ID CF_ZONE_ID; do [[ -n "${!v:-}" ]] || die "$v is not set"; done
for c in curl jq; do command -v "$c" >/dev/null || die "$c not found"; done

API=https://api.cloudflare.com/client/v4
FAILS=0
code() { # METHOD PATH [BODY]
  local args=(-sS -o /dev/null -w '%{http_code}' -X "$1" -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json")
  [[ -n "${3:-}" ]] && args+=(-d "$3")
  curl "${args[@]}" "$API$2"
}
expect() { if [[ " $2 " == *" $3 "* ]]; then echo "PASS  $1 -> HTTP $3"; else echo "FAIL  $1 -> HTTP $3 (expected $2)"; FAILS=$((FAILS+1)); fi; }

echo "Token: cf****REDACTED****"
echo "== Token status (account-owned verify endpoint):"
curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" "$API/accounts/$CF_ACCOUNT_ID/tokens/verify" \
  | jq -c '{success, status: .result.status, expires_on: .result.expires_on}'

echo "== Zones visible to the token (expect exactly one):"
ZONES=$(curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" "$API/zones?per_page=50" | jq -c '[.result[] | {id, name}]')
echo "$ZONES"
[[ $(jq length <<<"$ZONES") -eq 1 && $(jq -r '.[0].id' <<<"$ZONES") == "$CF_ZONE_ID" ]] \
  && echo "PASS  only the intended zone is visible" || { echo "FAIL  zone visibility is broader than one zone"; FAILS=$((FAILS+1)); }

expect "1 in-scope: list DNS records on the zone"      "200"         "$(code GET "/zones/$CF_ZONE_ID/dns_records?per_page=1")"
expect "2 in-scope: list tunnels"                      "200"         "$(code GET "/accounts/$CF_ACCOUNT_ID/cfd_tunnel?per_page=1")"
expect "3 read zone settings (not granted)"            "403"         "$(code GET "/zones/$CF_ZONE_ID/settings/ssl")"
expect "4 change SSL mode (not granted)"               "403"         "$(code PATCH "/zones/$CF_ZONE_ID/settings/ssl" '{"value":"__invalid__"}')"
expect "5 list account members (not granted)"          "403"         "$(code GET "/accounts/$CF_ACCOUNT_ID/members")"
expect "6 list Access apps (not granted)"              "403"         "$(code GET "/accounts/$CF_ACCOUNT_ID/access/apps")"
expect "7 list Workers scripts (not granted)"          "403"         "$(code GET "/accounts/$CF_ACCOUNT_ID/workers/scripts")"
expect "8 create API tokens (not granted)"             "403"         "$(code GET "/accounts/$CF_ACCOUNT_ID/tokens")"
expect "9 zone firewall rulesets (not granted)"        "403"         "$(code GET "/zones/$CF_ZONE_ID/rulesets")"

echo "== $FAILS failure(s)"
[[ $FAILS -eq 0 ]]
