#!/usr/bin/env bash
# D1 verification: a direct push to the site repo's main branch must be rejected.
#
# This attempts a REAL push to a live repo whose main deploys to production (Vercel).
# Guards, in order:
#   1. Refuses unless --confirm is passed.
#   2. Refuses unless the `protect-main` ruleset is active on the default branch (read via API).
#   3. The pushed commit is empty (same tree as main), so even if the push were wrongly accepted
#      the deployed site content would not change.
# Exit 0 = push rejected (control works). Exit 1 = push accepted (control FAILED) or precondition failed.
#
# Usage: deploy/scripts/d1/verify_site_push_blocked.sh <owner/repo> --confirm
set -euo pipefail

REPO="${1:-}"
CONFIRM="${2:-}"
die() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "$REPO" && "$REPO" == */* ]] || die "usage: $0 <owner/repo> --confirm"
[[ "$CONFIRM" == "--confirm" ]] || die "refusing to push to a live repo without --confirm"
command -v gh >/dev/null || die "gh CLI not found"
command -v git >/dev/null || die "git not found"

BRANCH="$(gh api "repos/$REPO" --jq .default_branch)"
echo "== Active rules on $REPO:$BRANCH"
RULES="$(gh api "repos/$REPO/rules/branches/$BRANCH" --jq '[.[].type] | sort | join(",")')"
echo "$RULES"
for r in pull_request non_fast_forward deletion required_signatures; do
  [[ ",$RULES," == *",$r,"* ]] || die "rule '$r' is not active on $BRANCH; not attempting the push"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "== Cloning $REPO (depth 1) into a temp dir"
gh repo clone "$REPO" "$WORK/repo" -- --depth 1 --branch "$BRANCH" --quiet
cd "$WORK/repo"

# Identity is set only inside this throwaway clone, never globally (owner rule: no git identity on this machine).
git -c user.name="d1-verification" -c user.email="d1-verification@invalid" \
  commit --allow-empty --quiet -m "test(d1): direct push to $BRANCH must be rejected"

echo "== Attempting: git push origin HEAD:$BRANCH"
set +e
OUT="$(git push origin "HEAD:$BRANCH" 2>&1)"
RC=$?
set -e
echo "$OUT" | sed -E 's#(https://)[^@/]+@#\1****REDACTED****@#g'
echo "push exit code: $RC"

if [[ $RC -ne 0 ]] && grep -qiE "rule violations|protected branch|GH013|declined" <<<"$OUT"; then
  echo "RESULT: PASS - direct push to $BRANCH was rejected by repository rules"
  exit 0
fi
if [[ $RC -eq 0 ]]; then
  echo "RESULT: FAIL - direct push was ACCEPTED. Empty commit is now on $BRANCH; revert via PR and treat as an incident." >&2
else
  echo "RESULT: FAIL - push failed for a reason other than repository rules; inspect output above" >&2
fi
exit 1
