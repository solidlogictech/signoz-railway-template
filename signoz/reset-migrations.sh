#!/bin/sh
set -e

CH="clickhouse-client --host clickhouse.railway.internal --port 9000 --user default --password signoz123"

echo "=== Step 1: Clear failed migration entries ==="
for db in signoz_metrics signoz_logs signoz_traces signoz_metadata signoz_analytics; do
  echo "Clearing failed entries in $db..."
  $CH --query "ALTER TABLE $db.schema_migrations_v2 DELETE WHERE status = 'failed'" 2>/dev/null || echo "  (skipped)"
done

echo ""
echo "=== Step 2: Add missing columns (migration 1007) ==="

# Add inserted_at_unix_milli to metrics tables
for tbl in samples_v4 distributed_samples_v4 time_series_v4 distributed_time_series_v4 exp_hist distributed_exp_hist; do
  echo "Adding inserted_at_unix_milli to signoz_metrics.$tbl..."
  $CH --query "ALTER TABLE signoz_metrics.$tbl ADD COLUMN IF NOT EXISTS inserted_at_unix_milli Int64 CODEC(ZSTD(1))" 2>/dev/null || echo "  (failed or exists)"
done

echo ""
echo "=== Step 3: Mark migration 1007 as finished ==="
$CH --query "INSERT INTO signoz_metrics.schema_migrations_v2 (migration_id, status, created_at) VALUES (1007, 'finished', now64())" 2>/dev/null || echo "  (may already exist)"

echo ""
echo "=== Step 4: Verify columns exist ==="
$CH --query "SELECT name, type FROM system.columns WHERE database = 'signoz_metrics' AND table = 'samples_v4' AND name = 'inserted_at_unix_milli'" 2>/dev/null
$CH --query "SELECT name, type FROM system.columns WHERE database = 'signoz_metrics' AND table = 'distributed_samples_v4' AND name = 'inserted_at_unix_milli'" 2>/dev/null
$CH --query "SELECT name, type FROM system.columns WHERE database = 'signoz_metrics' AND table = 'time_series_v4' AND name = 'inserted_at_unix_milli'" 2>/dev/null
$CH --query "SELECT name, type FROM system.columns WHERE database = 'signoz_metrics' AND table = 'distributed_time_series_v4' AND name = 'inserted_at_unix_milli'" 2>/dev/null

echo ""
echo "=== Step 5: Show all migration statuses ==="
for db in signoz_metrics signoz_logs signoz_traces; do
  echo "$db:"
  $CH --query "SELECT migration_id, status FROM $db.schema_migrations_v2 FINAL ORDER BY migration_id" 2>/dev/null || echo "  (no table)"
done

echo ""
echo "Done. Redeploy signoz-otel-collector."
