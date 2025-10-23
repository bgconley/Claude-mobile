#!/bin/bash
# Mixed Workload Test
# This test simulates a realistic workload with both reads and writes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="mixed-workload"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

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

# Create test dataset
log_info "[3/4] Creating test dataset..."
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
log_info "[4/4] Running mixed read/write benchmark..."
# Services will be stopped by trap on exit
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
