#!/usr/bin/env bash
# emergency-stop.sh — halt all outbound, publishing and scheduled work IMMEDIATELY.
# Must work from the host CLI even when the console is down (Phase D6 requirement).
# Order matters: outbound first. A wrong email cannot be recalled.
set -euo pipefail

COMPOSE="${COMPOSE:-docker compose -f /opt/vge/ops/compose/compose.prod.yaml}"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "[$STAMP] EMERGENCY STOP initiated by ${USER:-unknown}"

echo "1/5 Setting the global stop flag..."
$COMPOSE exec -T redis redis-cli --no-auth-warning -a "${REDIS_PASSWORD:?REDIS_PASSWORD not set}" \
  SET vge:emergency_stop 1 || echo "  !! could not set flag — continuing to hard stops"

echo "2/5 Stopping the scheduler (no new work)..."
$COMPOSE stop scheduler || true

echo "3/5 Stopping workers (halts sends and publishes)..."
$COMPOSE stop worker || true

echo "4/5 Verifying nothing is still processing..."
$COMPOSE ps

echo "5/5 In-flight state at stop time:"
$COMPOSE exec -T redis redis-cli --no-auth-warning -a "${REDIS_PASSWORD}" \
  LLEN vge:queue:outbound 2>/dev/null || true

cat <<NOTE

STOP COMPLETE — verify before standing down:
  - Confirm no messages left the system after $STAMP (check the provider's log).
  - Confirm no PR was merged after $STAMP.
  - Record this event in deploy/verification/DEPLOY_LOG.md.

Do NOT restart until the cause is understood and the operator explicitly approves.
Restart procedure: deploy/runbooks/EMERGENCY_STOP.md
NOTE
