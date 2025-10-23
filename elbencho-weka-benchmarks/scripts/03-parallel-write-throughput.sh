#!/bin/bash
# Parallel Write Throughput Test
# This test measures throughput with multiple files being written in parallel

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="parallel-write-throughput"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

echo "================================================================"
echo "  Parallel Write Throughput Test (Multiple Files)"
echo "================================================================"
echo "  Block Size: $THROUGHPUT_BLOCK_SIZE"
echo "  Threads per Client: $THROUGHPUT_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  File Size: $THROUGHPUT_FILE_SIZE"
echo "  Files per Thread: $FILES_PER_THREAD"
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
log_info "[3/3] Running parallel write benchmark..."
# Services will be stopped by trap on exit
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
    --files "$FILES_PER_THREAD" \
    $DIRECT_IO_FLAG \
    --write \
    --mkdirs \
    --deletedirs \
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
