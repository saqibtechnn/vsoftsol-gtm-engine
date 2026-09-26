#!/usr/bin/env bash
# verify-backup.sh — restore the latest backup to a throwaway database and prove it works.
# An untested backup is not a backup. Run weekly; record results in deploy/verification/.
set -euo pipefail

: "${BACKUP_PATH:?set BACKUP_PATH to the backup file or object key}"
: "${VERIFY_DB_URL:?set VERIFY_DB_URL to a THROWAWAY database, never production}"

case "$VERIFY_DB_URL" in
  *prod*|*production*) echo "REFUSING: target looks like production."; exit 1;;
esac

START=$(date +%s)
echo "Restoring $BACKUP_PATH -> throwaway target..."
pg_restore --clean --if-exists --no-owner --dbname "$VERIFY_DB_URL" "$BACKUP_PATH"

echo "Checking integrity..."
psql "$VERIFY_DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
\echo -- row counts on critical tables (adjust once the schema exists)
SELECT 'audit_events' AS t, count(*) FROM audit_events
UNION ALL SELECT 'contacts', count(*) FROM contacts
UNION ALL SELECT 'suppressions', count(*) FROM suppressions;
SQL

END=$(date +%s)
echo
echo "Restore completed in $((END-START))s."
echo "NOW DO THE PART THAT MATTERS: run the application against this database and confirm it works."
echo "Record the measured RTO/RPO in deploy/verification/DRILL_$(date -u +%F).md"
