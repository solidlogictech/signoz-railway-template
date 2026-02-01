#!/bin/sh
set -e

CH="clickhouse-client --host clickhouse.railway.internal --port 9000 --user default --password signoz123"

echo "=== Fix: Missing logs_v2 table ==="
echo ""
echo "Root cause: Fresh install skips squashed migrations because no legacy"
echo "schema_migrations table exists. The squashed migrations create logs_v2."
echo ""

echo "Step 1: Show current signoz_logs tables..."
$CH --query "SHOW TABLES FROM signoz_logs" 2>/dev/null || echo "  (database doesn't exist)"

echo ""
echo "Step 2: Drop signoz_logs database to start fresh..."
$CH --query "DROP DATABASE IF EXISTS signoz_logs ON CLUSTER cluster" 2>/dev/null || \
$CH --query "DROP DATABASE IF EXISTS signoz_logs" 2>/dev/null || echo "  (failed)"

echo ""
echo "Step 3: Recreate signoz_logs database..."
$CH --query "CREATE DATABASE IF NOT EXISTS signoz_logs ON CLUSTER cluster" 2>/dev/null || \
$CH --query "CREATE DATABASE IF NOT EXISTS signoz_logs" 2>/dev/null || echo "  (failed)"

echo ""
echo "Step 4: Create legacy schema_migrations table to trigger squashed migrations..."
$CH --query "CREATE TABLE IF NOT EXISTS signoz_logs.schema_migrations (
    version Int64,
    dirty UInt8,
    sequence UInt64
) ENGINE = MergeTree ORDER BY (version)" 2>/dev/null || echo "  (failed)"

echo ""
echo "Step 5: Insert a dummy row so shouldRunSquashed returns true..."
$CH --query "INSERT INTO signoz_logs.schema_migrations (version, dirty, sequence) VALUES (1, 0, 1)" 2>/dev/null || echo "  (failed)"

echo ""
echo "Step 6: Verify legacy table exists..."
$CH --query "SELECT count(*) FROM signoz_logs.schema_migrations" 2>/dev/null || echo "  (failed)"

echo ""
echo "Step 7: Show all signoz_logs tables after fix..."
$CH --query "SHOW TABLES FROM signoz_logs" 2>/dev/null || echo "  (failed)"

echo ""
echo "=== Done. Now redeploy schema-migrator to run squashed migrations. ==="
