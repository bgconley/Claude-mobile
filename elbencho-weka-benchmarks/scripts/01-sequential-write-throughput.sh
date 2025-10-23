#!/bin/bash
# Sequential Write Throughput Test
# This test measures maximum write throughput with large sequential writes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="sequential-write-throughput"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

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
log_info "[1/3] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services on all clients with error handling
log_info "[2/3] Starting elbencho services on all clients..."
start_all_services

# Run the benchmark from master
log_info "[3/3] Running sequential write benchmark..."
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

# Check if elbencho succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "elbencho command failed"
    exit 1
fi

# Services will be stopped by trap on exit
echo ""
log_success "Test Complete!"
log_info "Results saved to: $OUTPUT_FILE"
