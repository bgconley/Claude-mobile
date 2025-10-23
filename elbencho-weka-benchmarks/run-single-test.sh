#!/bin/bash
# Run a single benchmark test
# Usage: ./run-single-test.sh <test-number>

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load configuration
source configs/cluster.conf

# Print usage
usage() {
    echo "Usage: $0 <test-number>"
    echo ""
    echo "Available tests:"
    echo "  1 - Sequential Write Throughput"
    echo "  2 - Sequential Read Throughput"
    echo "  3 - Parallel Write Throughput"
    echo "  4 - Parallel Read Throughput"
    echo "  5 - Random Write Latency"
    echo "  6 - Random Read Latency"
    echo "  7 - Mixed Workload"
    echo "  8 - Metadata Operations"
    echo ""
    exit 1
}

# Check argument
if [ $# -ne 1 ]; then
    usage
fi

TEST_NUM=$1

# Create results directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results/single-test_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Save configuration
cp configs/cluster.conf "$RESULTS_DIR/cluster.conf"

echo "================================================================"
echo "  Running Single Test"
echo "================================================================"
echo "  Timestamp: $(date)"
echo "  Results: $RESULTS_DIR"
echo "================================================================"
echo ""

# Run selected test
case $TEST_NUM in
    1)
        bash scripts/01-sequential-write-throughput.sh "$RESULTS_DIR"
        ;;
    2)
        bash scripts/02-sequential-read-throughput.sh "$RESULTS_DIR"
        ;;
    3)
        bash scripts/03-parallel-write-throughput.sh "$RESULTS_DIR"
        ;;
    4)
        bash scripts/04-parallel-read-throughput.sh "$RESULTS_DIR"
        ;;
    5)
        bash scripts/05-random-write-latency.sh "$RESULTS_DIR"
        ;;
    6)
        bash scripts/06-random-read-latency.sh "$RESULTS_DIR"
        ;;
    7)
        bash scripts/07-mixed-workload.sh "$RESULTS_DIR"
        ;;
    8)
        bash scripts/08-metadata-operations.sh "$RESULTS_DIR"
        ;;
    *)
        echo "Invalid test number: $TEST_NUM"
        usage
        ;;
esac

echo ""
echo "================================================================"
echo "  Test Complete!"
echo "  Results saved to: $RESULTS_DIR"
echo "================================================================"
