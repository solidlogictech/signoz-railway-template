#!/bin/sh
set -e

CH="clickhouse-client --host clickhouse.railway.internal --port 9000 --user default --password signoz123"

echo "Clearing failed migration entries from all databases..."

for db in signoz_metrics signoz_logs signoz_traces signoz_metadata signoz_analytics; do
  echo "Clearing $db..."
  $CH --query "ALTER TABLE $db.schema_migrations_v2 DELETE WHERE status = 'failed'" 2>/dev/null || echo "  (table may not exist in $db, skipping)"
done

echo "Verifying..."
for db in signoz_metrics signoz_logs signoz_traces signoz_metadata signoz_analytics; do
  echo "$db migrations:"
  $CH --query "SELECT migration_id, status FROM $db.schema_migrations_v2 FINAL ORDER BY migration_id" 2>/dev/null || echo "  (no table)"
done

echo "Done. Now redeploy schema-migrator-async."
