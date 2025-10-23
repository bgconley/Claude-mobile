#!/bin/bash
# Random Write Latency Test
# This test measures write latency with small random I/O operations

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="random-write-latency"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

echo "================================================================"
echo "  Random Write Latency Test"
echo "================================================================"
echo "  Block Size: $LATENCY_BLOCK_SIZE (small blocks for latency)"
echo "  Threads per Client: $LATENCY_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  File Size: $LATENCY_FILE_SIZE"
echo "  Test Directory: $TEST_DIR"
echo "================================================================"
# Services will be stopped by trap on exit
echo ""

# Cleanup
log_info "[1/3] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services
log_info "[2/3] Starting elbencho services on all clients..."
start_all_services

# Run benchmark
log_info "[3/3] Running random write latency benchmark..."
# Services will be stopped by trap on exit
echo ""

DIRECT_IO_FLAG=""
if [ "$USE_DIRECT_IO" = "1" ]; then
    DIRECT_IO_FLAG="--direct"
fi

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$LATENCY_THREADS" \
    --size "$LATENCY_FILE_SIZE" \
    --block "$LATENCY_BLOCK_SIZE" \
    $DIRECT_IO_FLAG \
    --random \
    --write \
    --mkdirs \
    --deletedirs \
    --lat \
    --lathisto \
    --latpercent \
    "$TEST_DIR" \
    2>&1 | tee "$OUTPUT_FILE"

# Check if elbencho succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "elbencho command failed"
    exit 1
fi

# Stop services
# Services will be stopped by trap on exit
echo ""
