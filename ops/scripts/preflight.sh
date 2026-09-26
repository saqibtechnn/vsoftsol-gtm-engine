#!/usr/bin/env bash
# preflight.sh — verify the local environment is ready to begin deployment work.
# Safe to run any time. Changes nothing.
set -euo pipefail

# Resolve the repo root so this script works from any directory.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ok=0; warn=0; fail=0
check() { # check <label> <command...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '  [ OK ]  %s\n' "$label"; ok=$((ok+1))
  else printf '  [FAIL]  %s\n' "$label"; fail=$((fail+1)); fi
}
soft() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '  [ OK ]  %s\n' "$label"; ok=$((ok+1))
  else printf '  [WARN]  %s (needed from a later phase)\n' "$label"; warn=$((warn+1)); fi
}

echo "VSoftSol GTM Engine — deployment preflight"
echo
echo "Required now:"
check "git installed"            git --version
check "docker installed"         docker --version
check "docker daemon reachable"  docker info
echo
echo "Required from Phase D2 onward:"
soft  "opentofu or terraform"    sh -c 'command -v tofu || command -v terraform'
soft  "ansible"                  ansible --version
echo
echo "Required from Phase D3 onward:"
soft  "cosign (image signing)"   cosign version
soft  "syft (SBOM)"              syft version
soft  "trivy (vuln scan)"        trivy --version
echo
echo "Required from Phase D5 onward:"
soft  "sops"                     sops --version
soft  "age"                      age --version
soft  "gitleaks"                 gitleaks version
echo
echo "Repository state:"
check "CLAUDE.md present"        test -f CLAUDE.md
check "phase files present"      test -f deploy/phases/PHASE_D0.md
check ".env not committed"       sh -c '! git ls-files --error-unmatch .env 2>/dev/null'
if [ -f .env ]; then printf '  [ OK ]  .env exists locally\n'; else printf '  [WARN]  .env missing — copy from .env.example\n'; warn=$((warn+1)); fi
echo
printf 'Passed: %d   Warnings: %d   Failed: %d\n' "$ok" "$warn" "$fail"
[ "$fail" -eq 0 ] || { echo "Resolve failures before starting Phase D0."; exit 1; }
echo "Preflight clear. Start with: /phase D0"
