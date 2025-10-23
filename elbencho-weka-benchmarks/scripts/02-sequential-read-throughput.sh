#!/bin/bash
# Sequential Read Throughput Test
# This test measures maximum read throughput with large sequential reads

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="sequential-read-throughput"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

echo "================================================================"
echo "  Sequential Read Throughput Test"
echo "================================================================"
echo "  Block Size: $THROUGHPUT_BLOCK_SIZE"
echo "  Threads per Client: $THROUGHPUT_THREADS"
echo "  Total Clients: $NUM_CLIENTS"
echo "  File Size: $THROUGHPUT_FILE_SIZE"
echo "  Test Directory: $TEST_DIR"
echo "================================================================"
echo ""

# Cleanup and prepare test data
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

# Create test files first
log_info "[3/4] Creating test files..."
elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$THROUGHPUT_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$THROUGHPUT_BLOCK_SIZE" \
    $DIRECT_IO_FLAG \
    --write \
    --mkdirs \
    "$TEST_DIR" \
    > /dev/null 2>&1

if [ $? -ne 0 ]; then
    log_error "Failed to create test files"
    exit 1
fi

# Run read benchmark
log_info "[4/4] Running sequential read benchmark..."
echo ""

elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads "$THROUGHPUT_THREADS" \
    --size "$THROUGHPUT_FILE_SIZE" \
    --block "$THROUGHPUT_BLOCK_SIZE" \
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

# Services will be stopped by trap on exit
echo ""
log_success "Test Complete!"
log_info "Results saved to: $OUTPUT_FILE"
