#!/bin/bash
# Sequential Write Throughput Test
# This test measures maximum write throughput with large sequential writes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="sequential-write-throughput"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

echo "================================================================"
echo "  Sequential Write Throughput Test"
echo "================================================================"
echo "  Block Size: $THROUGHPUT_BLOCK_SIZE"
echo "  Threads per Client: $THROUGHPUT_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  File Size: $THROUGHPUT_FILE_SIZE"
echo "  Test Directory: $TEST_DIR"
echo "================================================================"
echo ""

# Cleanup previous test data
echo "[1/3] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services on all clients
echo "[2/3] Starting elbencho services on all clients..."
for host in $CLIENT_HOSTS; do
    echo "  Starting service on $host..."
    ssh "$host" "elbencho --service --foreground" &
    sleep 1
done

sleep 3

# Run the benchmark from master
echo "[3/3] Running sequential write benchmark..."
echo ""

DIRECT_IO_FLAG=""
if [ "$USE_DIRECT_IO" = "1" ]; then
    DIRECT_IO_FLAG="--direct"
fi

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$THROUGHPUT_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$THROUGHPUT_BLOCK_SIZE" \
    $DIRECT_IO_FLAG \
    --write \
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
