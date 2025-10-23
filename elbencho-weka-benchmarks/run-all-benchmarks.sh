#!/bin/bash
# Main orchestration script for Weka elbencho benchmarks
# This script runs all benchmark scenarios and generates a summary report

set -e

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load configuration
source configs/cluster.conf

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print banner
print_banner() {
    echo "================================================================"
    echo "  Weka.io Storage Cluster Benchmark Suite (elbencho)"
    echo "================================================================"
    echo "  Timestamp: $(date)"
    echo "  Master: $MASTER_HOST"
    echo "  Clients: $NUM_CLIENTS ($CLIENT_HOSTS)"
    echo "  Mount Point: $WEKA_MOUNT"
    echo "  Benchmark Dir: $BENCHMARK_DIR"
    echo "================================================================"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if elbencho is installed
    if ! command -v elbencho &> /dev/null; then
        log_error "elbencho is not installed or not in PATH"
        exit 1
    fi

    # Check if running on master
    CURRENT_HOST=$(hostname)
    if [[ "$CURRENT_HOST" != "$MASTER_HOST" ]]; then
        log_warning "This script should be run on the master node ($MASTER_HOST), but running on $CURRENT_HOST"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check if Weka mount exists
    if [ ! -d "$WEKA_MOUNT" ]; then
        log_error "Weka mount point $WEKA_MOUNT does not exist"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Create results directory
create_results_dir() {
    RESULTS_DIR="results/run_${TIMESTAMP}"
    mkdir -p "$RESULTS_DIR"
    log_info "Results will be saved to: $RESULTS_DIR"
}

# Main execution
main() {
    print_banner
    check_prerequisites
    create_results_dir

    # Save configuration
    cp configs/cluster.conf "$RESULTS_DIR/cluster.conf"

    log_info "Starting benchmark suite..."
    echo ""

    # Run throughput benchmarks
    log_info "=== Phase 1: High Throughput Benchmarks ==="
    bash scripts/01-sequential-write-throughput.sh "$RESULTS_DIR" || log_error "Sequential write test failed"
    bash scripts/02-sequential-read-throughput.sh "$RESULTS_DIR" || log_error "Sequential read test failed"
    bash scripts/03-parallel-write-throughput.sh "$RESULTS_DIR" || log_error "Parallel write test failed"
    bash scripts/04-parallel-read-throughput.sh "$RESULTS_DIR" || log_error "Parallel read test failed"

    echo ""
    log_info "=== Phase 2: Low Latency Benchmarks ==="
    bash scripts/05-random-write-latency.sh "$RESULTS_DIR" || log_error "Random write latency test failed"
    bash scripts/06-random-read-latency.sh "$RESULTS_DIR" || log_error "Random read latency test failed"
    bash scripts/07-mixed-workload.sh "$RESULTS_DIR" || log_error "Mixed workload test failed"

    echo ""
    log_info "=== Phase 3: Metadata Performance ==="
    bash scripts/08-metadata-operations.sh "$RESULTS_DIR" || log_error "Metadata test failed"

    echo ""
    log_info "=== Generating Summary Report ==="
    bash scripts/generate-report.sh "$RESULTS_DIR"

    echo ""
    log_success "Benchmark suite completed!"
    log_info "Results location: $RESULTS_DIR"
    log_info "Summary report: $RESULTS_DIR/summary.txt"
}

# Handle interrupts
trap 'log_error "Benchmark interrupted!"; exit 130' INT TERM

# Run main
main "$@"
