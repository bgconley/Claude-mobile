#!/bin/bash
# Metadata Operations Test
# This test measures metadata performance (file create/stat/delete operations)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"
source "$SCRIPT_DIR/scripts/common-functions.sh"

RESULTS_DIR="${1:-results/latest}"
TEST_NAME="metadata-operations"
TEST_DIR="${BENCHMARK_DIR}/${TEST_NAME}"
OUTPUT_FILE="${RESULTS_DIR}/${TEST_NAME}.txt"

# Ensure services are cleaned up on exit
trap cleanup_services EXIT INT TERM

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
# Services will be stopped by trap on exit
echo ""

# Cleanup
log_info "[1/3] Cleaning up previous test data..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start services
log_info "[2/3] Starting elbencho services on all clients..."
start_all_services

# Run metadata benchmark
log_info "[3/3] Running metadata operations benchmark..."
# Services will be stopped by trap on exit
echo ""
echo "This test includes:"
echo "  - File creation"
echo "  - File stat operations"
echo "  - File deletion"
# Services will be stopped by trap on exit
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

# Check if elbencho succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "elbencho command failed"
    exit 1
fi

# Stop services
# Services will be stopped by trap on exit
echo ""
