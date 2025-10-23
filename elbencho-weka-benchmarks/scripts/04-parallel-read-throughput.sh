#!/bin/bash
# Parallel Read Throughput Test
# This test measures throughput with multiple files being read in parallel

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="parallel-read-throughput"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

echo "================================================================"
echo "  Parallel Read Throughput Test (Multiple Files)"
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

# Cleanup and prepare
log_info "[1/4] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services
log_info "[2/4] Starting elbencho services on all clients..."
start_all_services

DIRECT_IO_FLAG=""
if [ "$USE_DIRECT_IO" = "1" ]; then
    DIRECT_IO_FLAG="--direct"
fi

# Create test files
log_info "[3/4] Creating test files..."
elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$THROUGHPUT_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$THROUGHPUT_BLOCK_SIZE" \
    --files "$FILES_PER_THREAD" \
    $DIRECT_IO_FLAG \
    --write \
    --mkdirs \
    "$TEST_DIR" \
    > /dev/null 2>&1

# Run read benchmark
log_info "[4/4] Running parallel read benchmark..."
# Services will be stopped by trap on exit
echo ""

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$THROUGHPUT_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$THROUGHPUT_BLOCK_SIZE" \
    --files "$FILES_PER_THREAD" \
    $DIRECT_IO_FLAG \
    --read \
    "$TEST_DIR" \
    2>&1 | tee "$OUTPUT_FILE"

# Check if elbencho succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "elbencho command failed"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DIR"

# Stop services
# Services will be stopped by trap on exit
echo ""
