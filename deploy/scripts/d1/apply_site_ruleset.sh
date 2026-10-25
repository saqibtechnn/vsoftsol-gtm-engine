#!/usr/bin/env bash
# Apply (or update in place) the `protect-main` ruleset on the site repo.
# Idempotent: finds an existing ruleset by name and PUTs over it instead of creating a duplicate.
# Dry-run by default because this changes a live repo's push rules; pass --apply to change anything.
#
# Usage: deploy/scripts/d1/apply_site_ruleset.sh <owner/repo> [--apply]
set -euo pipefail

REPO="${1:-}"
MODE="${2:-}"
RULESET_FILE="$(cd "$(dirname "$0")/../../.." && pwd)/ops/github/site-main-ruleset.json"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "$REPO" && "$REPO" == */* ]] || die "usage: $0 <owner/repo> [--apply]"
[[ -z "$MODE" || "$MODE" == "--apply" ]] || die "unknown argument: $MODE"
command -v gh >/dev/null || die "gh CLI not found"
[[ -f "$RULESET_FILE" ]] || die "ruleset file missing: $RULESET_FILE"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

NAME="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$RULESET_FILE" | head -1)"
[[ -n "$NAME" ]] || die "could not read ruleset name from $RULESET_FILE"

# Rulesets on a private repo of a Free account are rejected by GitHub; check first so the failure is explicit.
VISIBILITY="$(gh api "repos/$REPO" --jq .visibility)"
echo "Repo:       $REPO (visibility: $VISIBILITY)"
echo "Ruleset:    $NAME from $RULESET_FILE"
if [[ "$VISIBILITY" != "public" ]]; then
  echo "WARNING: $REPO is $VISIBILITY. On GitHub Free, rulesets are not available for private repos." >&2
fi

EXISTING_ID="$(gh api "repos/$REPO/rulesets" --jq ".[] | select(.name == \"$NAME\") | .id" | head -1)"

if [[ -n "$EXISTING_ID" ]]; then
  ACTION="update ruleset id $EXISTING_ID (PUT repos/$REPO/rulesets/$EXISTING_ID)"
else
  ACTION="create ruleset (POST repos/$REPO/rulesets)"
fi
echo "About to:   $ACTION"

if [[ "$MODE" != "--apply" ]]; then
  echo "Dry run. Re-run with --apply to make this change."
  exit 0
fi

if [[ -n "$EXISTING_ID" ]]; then
  gh api --method PUT "repos/$REPO/rulesets/$EXISTING_ID" --input "$RULESET_FILE" \
    --jq '{id, name, enforcement, rules: [.rules[].type], bypass: .bypass_actors}'
else
  gh api --method POST "repos/$REPO/rulesets" --input "$RULESET_FILE" \
    --jq '{id, name, enforcement, rules: [.rules[].type], bypass: .bypass_actors}'
fi
echo "Done. Rollback: gh api --method DELETE repos/$REPO/rulesets/<id>"
