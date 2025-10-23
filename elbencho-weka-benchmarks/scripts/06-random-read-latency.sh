#!/bin/bash
# Random Read Latency Test
# This test measures read latency with small random I/O operations

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="random-read-latency"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

echo "================================================================"
echo "  Random Read Latency Test"
echo "================================================================"
echo "  Block Size: $LATENCY_BLOCK_SIZE (small blocks for latency)"
echo "  Threads per Client: $LATENCY_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  File Size: $LATENCY_FILE_SIZE"
echo "  Test Directory: $TEST_DIR"
echo "================================================================"
echo ""

# Cleanup and prepare
echo "[1/4] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services
echo "[2/4] Starting elbencho services on all clients..."
for host in $CLIENT_HOSTS; do
    echo "  Starting service on $host..."
    ssh "$host" "elbencho --service --foreground" &
    sleep 1
done

sleep 3

DIRECT_IO_FLAG=""
if [ "$USE_DIRECT_IO" = "1" ]; then
    DIRECT_IO_FLAG="--direct"
fi

# Create test files
echo "[3/4] Creating test files..."
elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$LATENCY_THREADS" \
    --size "$LATENCY_FILE_SIZE" \
    --block "$LATENCY_BLOCK_SIZE" \
    $DIRECT_IO_FLAG \
    --write \
    --mkdirs \
    "$TEST_DIR" \
    > /dev/null 2>&1

# Run read latency benchmark
echo "[4/4] Running random read latency benchmark..."
echo ""

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$LATENCY_THREADS" \
    --size "$LATENCY_FILE_SIZE" \
    --block "$LATENCY_BLOCK_SIZE" \
    $DIRECT_IO_FLAG \
    --random \
    --read \
    --lat \
    --lathisto \
    --latpercent \
    "$TEST_DIR" \
    2>&1 | tee "$OUTPUT_FILE"

# Cleanup
rm -rf "$TEST_DIR"

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
