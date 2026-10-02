#!/usr/bin/env bash
# D1 verification: the VGE GitHub App can reach the site repo with exactly its documented
# permissions and nothing else. Every check attempts an action OUTSIDE scope and expects denial,
# except check 1, which proves the token works at all (a dead token would "pass" every denial).
#
# Inputs (env):
#   GH_APP_ID            numeric App ID
#   GH_APP_KEY_FILE      path to the App private key (.pem). Read, never printed.
#   GH_APP_SITE_REPO     owner/repo the App is installed on (the only allowed repo)
#   GH_APP_OTHER_REPO    owner/repo the App is NOT installed on (expect 404)
# Requires: openssl, curl, jq. Run in Codespaces, not on the host.
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
for v in GH_APP_ID GH_APP_KEY_FILE GH_APP_SITE_REPO GH_APP_OTHER_REPO; do
  [[ -n "${!v:-}" ]] || die "$v is not set"
done
[[ -r "$GH_APP_KEY_FILE" ]] || die "cannot read GH_APP_KEY_FILE"
for c in openssl curl jq; do command -v "$c" >/dev/null || die "$c not found"; done

API=https://api.github.com
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# App JWT (RS256, 9 min) -> installation token for the site repo only.
now=$(date +%s)
header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' $((now-60)) $((now+540)) "$GH_APP_ID" | b64url)
sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign "$GH_APP_KEY_FILE" | b64url)
JWT="$header.$payload.$sig"

INST_ID=$(curl -fsS -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  "$API/repos/$GH_APP_SITE_REPO/installation" | jq -r .id)
[[ "$INST_ID" =~ ^[0-9]+$ ]] || die "App is not installed on $GH_APP_SITE_REPO"
TOKEN=$(curl -fsS -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
  "$API/app/installations/$INST_ID/access_tokens" | jq -r .token)
[[ -n "$TOKEN" && "$TOKEN" != null ]] || die "could not mint installation token"
unset JWT

FAILS=0
# call METHOD PATH [BODY] -> prints HTTP status only
call() {
  local m=$1 p=$2 body=${3:-}
  if [[ -n "$body" ]]; then
    curl -sS -o /dev/null -w '%{http_code}' -X "$m" -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github+json" "$API$p" -d "$body"
  else
    curl -sS -o /dev/null -w '%{http_code}' -X "$m" -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github+json" "$API$p"
  fi
}
expect() { # name expected-codes actual
  if [[ " $2 " == *" $3 "* ]]; then echo "PASS  $1 -> HTTP $3"; else echo "FAIL  $1 -> HTTP $3 (expected $2)"; FAILS=$((FAILS+1)); fi
}

echo "Token: ghs_****REDACTED**** (installation $INST_ID, expires in <= 60 min)"
echo "== Granted permissions on the token:"
curl -fsS -H "Authorization: token $TOKEN" "$API/installation/repositories" \
  | jq -c '{total_count, repos: [.repositories[].full_name]}'

expect "1 in-scope: read site repo"                 "200"     "$(call GET "/repos/$GH_APP_SITE_REPO")"
expect "2 other repo is invisible"                  "404"     "$(call GET "/repos/$GH_APP_OTHER_REPO")"
expect "3 read repo rulesets (admin) denied"        "403 404" "$(call GET "/repos/$GH_APP_SITE_REPO/rulesets/rule-suites")"
expect "4 change repo settings denied"              "403 404" "$(call PATCH "/repos/$GH_APP_SITE_REPO" '{"has_wiki":false}')"
expect "5 list webhooks (admin) denied" "403 404" "$(call GET "/repos/$GH_APP_SITE_REPO/hooks")"
expect "6 add a collaborator denied"                "403 404" "$(call PUT "/repos/$GH_APP_SITE_REPO/collaborators/octocat" '{"permission":"pull"}')"
expect "7 Actions secrets denied"                   "403 404" "$(call GET "/repos/$GH_APP_SITE_REPO/actions/secrets")"
expect "8 create a repo denied"                     "403 404" "$(call POST "/user/repos" '{"name":"d1-scope-test"}')"
# Direct write to main with contents:write must be stopped by the ruleset (rule violation = 409/422).
# Guard: if the ruleset is not active this write WOULD land on main and deploy, so check first.
ACTIVE=$(curl -fsS "$API/repos/$GH_APP_SITE_REPO/rules/branches/main" | jq -r '[.[].type] | index("pull_request") != null')
[[ "$ACTIVE" == "true" ]] || die "pull_request rule not active on main; refusing to attempt check 9"
MAIN_SHA=$(curl -fsS -H "Authorization: token $TOKEN" "$API/repos/$GH_APP_SITE_REPO/contents/robots.txt" | jq -r .sha)
expect "9 commit directly to main denied by ruleset" "403 409 422" \
  "$(call PUT "/repos/$GH_APP_SITE_REPO/contents/robots.txt" "{\"message\":\"test(d1): must be rejected\",\"content\":\"\",\"sha\":\"$MAIN_SHA\"}")"

# Revocation: the installation token is revoked here and must stop working immediately.
expect "10 revoke installation token"               "204"     "$(call DELETE "/installation/token")"
expect "11 revoked token rejected"                  "401"     "$(call GET "/repos/$GH_APP_SITE_REPO")"
unset TOKEN

echo "== $FAILS failure(s)"
[[ $FAILS -eq 0 ]]
