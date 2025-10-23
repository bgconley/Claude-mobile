#!/bin/bash
# Metadata Operations Test
# This test measures metadata performance (file create/stat/delete operations)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="metadata-operations"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Metadata test parameters
METADATA_THREADS=16
METADATA_FILES=10000
METADATA_FILE_SIZE="4K"

echo "================================================================"
echo "  Metadata Operations Test"
echo "================================================================"
echo "  Threads per Client: $METADATA_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  Files to Create: $METADATA_FILES per thread"
echo "  File Size: $METADATA_FILE_SIZE (small files)"
echo "  Test Directory: $TEST_DIR"
echo "================================================================"
echo ""

# Cleanup
echo "[1/3] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services
echo "[2/3] Starting elbencho services on all clients..."
for host in $CLIENT_HOSTS; do
    echo "  Starting service on $host..."
    ssh "$host" "elbencho --service --foreground" &
    sleep 1
done

sleep 3

# Run metadata benchmark
echo "[3/3] Running metadata operations benchmark..."
echo ""
echo "This test includes:"
echo "  - File creation"
echo "  - File stat operations"
echo "  - File deletion"
echo ""

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$METADATA_THREADS" \
    --size "$METADATA_FILE_SIZE" \
    --files "$METADATA_FILES" \
    --write \
    --read \
    --statfiles \
    --mkdirs \
    --deletedirs \
    "$TEST_DIR" \
    2>&1 | tee "$OUTPUT_FILE"

# Stop services
echo ""
echo "Stopping elbencho services..."
for host in $CLIENT_HOSTS; do
    ssh "$host" "pkill -f 'elbencho --service'" || true
done

echo ""
echo "================================================================"
echo "  Test Complete!"
echo "  Results saved to: $OUTPUT_FILE"
echo "================================================================"
