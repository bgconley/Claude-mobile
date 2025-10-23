#!/bin/bash
# Mixed Workload Test
# This test simulates a realistic workload with both reads and writes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="mixed-workload"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Mixed workload parameters
MIXED_BLOCK_SIZE="128K"  # Medium block size for mixed workload
MIXED_THREADS=12

echo "================================================================"
echo "  Mixed Read/Write Workload Test"
echo "================================================================"
echo "  Block Size: $MIXED_BLOCK_SIZE"
echo "  Threads per Client: $MIXED_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  Read/Write Ratio: 70/30"
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

# Create test dataset
echo "[3/4] Creating test dataset..."
elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$MIXED_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$MIXED_BLOCK_SIZE" \
    --files "$FILES_PER_THREAD" \
    $DIRECT_IO_FLAG \
    --write \
    --mkdirs \
    "$TEST_DIR" \
    > /dev/null 2>&1

# Run mixed workload (70% read, 30% write)
echo "[4/4] Running mixed read/write benchmark..."
echo ""

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$MIXED_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$MIXED_BLOCK_SIZE" \
    --files "$FILES_PER_THREAD" \
    $DIRECT_IO_FLAG \
    --random \
    --read \
    --rwmixpercent 70 \
    --lat \
    --lathisto \
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
