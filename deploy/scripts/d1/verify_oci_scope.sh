#!/usr/bin/env bash
# D1 verification: OCI machine identities are confined to the `vge` compartment (vge-tofu) or
# the backup bucket (vge-backup). Denial checks are reads at tenancy scope, so a wrongly-broad
# policy is detected without creating anything.
#
# Inputs (env):
#   OCI_CLI_PROFILE       profile in ~/.oci/config for the identity under test (e.g. VGE_TOFU)
#   OCI_TENANCY_OCID      tenancy OCID (root compartment)
#   OCI_VGE_COMPARTMENT   OCID of the `vge` compartment
#   OCI_IDENTITY          vge-tofu | vge-backup
#   OCI_BACKUP_BUCKET     bucket name (vge-backup only)
# Requires: oci CLI, jq. Run in Codespaces.
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
for v in OCI_CLI_PROFILE OCI_TENANCY_OCID OCI_VGE_COMPARTMENT OCI_IDENTITY; do [[ -n "${!v:-}" ]] || die "$v is not set"; done
for c in oci jq; do command -v "$c" >/dev/null || die "$c not found"; done

FAILS=0
# run NAME EXPECT(ok|denied) -- oci args...
run() {
  local name=$1 want=$2; shift 3
  local out rc
  set +e; out=$(oci --profile "$OCI_CLI_PROFILE" "$@" 2>&1); rc=$?; set -e
  local got=ok
  if [[ $rc -ne 0 ]]; then
    if grep -qE 'NotAuthorized|NotAuthenticated|"status": 40[134]' <<<"$out"; then got=denied; else got="error(rc=$rc)"; fi
  fi
  if [[ "$got" == "$want" ]]; then echo "PASS  $name -> $got"; else
    echo "FAIL  $name -> $got (expected $want)"; grep -oE '"(code|message)": "[^"]*"' <<<"$out" | head -2; FAILS=$((FAILS+1)); fi
}

echo "Identity under test: $OCI_IDENTITY (profile $OCI_CLI_PROFILE; key ****REDACTED****)"
NS=$(oci --profile "$OCI_CLI_PROFILE" os ns get --query data --raw-output 2>/dev/null || true)

case "$OCI_IDENTITY" in
  vge-tofu)
    run "1 in-scope: list instances in vge"          ok     -- compute instance list -c "$OCI_VGE_COMPARTMENT"
    run "2 in-scope: list VCNs in vge"               ok     -- network vcn list -c "$OCI_VGE_COMPARTMENT"
    run "3 list instances in ROOT compartment"       denied -- compute instance list -c "$OCI_TENANCY_OCID"
    run "4 list IAM users"                           denied -- iam user list -c "$OCI_TENANCY_OCID"
    run "5 list IAM policies at root"                denied -- iam policy list -c "$OCI_TENANCY_OCID"
    run "6 list budgets"                             denied -- budgets budget list -c "$OCI_TENANCY_OCID"
    ;;
  vge-backup)
    [[ -n "${OCI_BACKUP_BUCKET:-}" ]] || die "OCI_BACKUP_BUCKET is not set"
    run "1 in-scope: list objects in backup bucket"  ok     -- os object list -ns "$NS" -bn "$OCI_BACKUP_BUCKET" --limit 1
    run "2 list buckets in vge compartment"          denied -- os bucket list -ns "$NS" -c "$OCI_VGE_COMPARTMENT"
    run "3 list instances in vge"                    denied -- compute instance list -c "$OCI_VGE_COMPARTMENT"
    run "4 list IAM users"                           denied -- iam user list -c "$OCI_TENANCY_OCID"
    # A read that needs bucket-level MANAGE; a destructive test (bucket delete) could succeed and destroy backups.
    run "5 read lifecycle policy (bucket manage)"    denied -- os object-lifecycle-policy get -ns "$NS" -bn "$OCI_BACKUP_BUCKET"
    ;;
  *) die "unknown OCI_IDENTITY: $OCI_IDENTITY" ;;
esac

echo "== $FAILS failure(s)"
[[ $FAILS -eq 0 ]]
