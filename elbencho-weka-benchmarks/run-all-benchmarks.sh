#!/bin/bash
# Main orchestration script for Weka elbencho benchmarks
# This script runs all benchmark scenarios and generates a summary report

set -e

FAILED_TESTS=()

record_failure() {
    local description=$1
    FAILED_TESTS+=("$description")
}

run_benchmark_script() {
    local description=$1
    local script_path=$2

    if ! bash "$script_path" "$RESULTS_DIR"; then
        log_error "$description failed"
        record_failure "$description"
        return 1
    fi

    return 0
}

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

# Check SSH connectivity
check_ssh_connectivity() {
    log_info "Checking SSH connectivity to all clients..."

    local ssh_failed=0
    local failed_hosts=""

    for host in $CLIENT_HOSTS; do
        echo -n "  Checking $host... "

        # Try passwordless SSH with timeout
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host" "exit" 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            ssh_failed=1
            failed_hosts="$failed_hosts $host"
        fi
    done

    if [ $ssh_failed -eq 1 ]; then
        echo ""
        log_error "Passwordless SSH is not configured for:$failed_hosts"
        log_error ""
        log_error "To fix this, run one of the following:"
        log_error "  1. Use the setup script: bash scripts/setup-passwordless-ssh.sh"
        log_error "  2. Manually set up SSH keys:"
        for host in $failed_hosts; do
            log_error "     ssh-copy-id $host"
        done
        echo ""
        exit 1
    fi

    log_success "SSH connectivity check passed"
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

    # Check SSH connectivity to all clients
    check_ssh_connectivity

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
    run_benchmark_script "Sequential write test" "scripts/01-sequential-write-throughput.sh"
    run_benchmark_script "Sequential read test" "scripts/02-sequential-read-throughput.sh"
    run_benchmark_script "Parallel write test" "scripts/03-parallel-write-throughput.sh"
    run_benchmark_script "Parallel read test" "scripts/04-parallel-read-throughput.sh"

    echo ""
    log_info "=== Phase 2: Low Latency Benchmarks ==="
    run_benchmark_script "Random write latency test" "scripts/05-random-write-latency.sh"
    run_benchmark_script "Random read latency test" "scripts/06-random-read-latency.sh"
    run_benchmark_script "Mixed workload test" "scripts/07-mixed-workload.sh"

    echo ""
    log_info "=== Phase 3: Metadata Performance ==="
    run_benchmark_script "Metadata operations test" "scripts/08-metadata-operations.sh"

    echo ""
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        log_warning "Some benchmarks failed. Generating summary with available results..."
    else
        log_info "=== Generating Summary Report ==="
    fi

    bash scripts/generate-report.sh "$RESULTS_DIR"

    echo ""
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        log_error "Benchmark suite completed with errors"
        log_error "Failed benchmarks:"
        for test in "${FAILED_TESTS[@]}"; do
            log_error "  - $test"
        done
        exit 1
    else
        log_success "Benchmark suite completed!"
        log_info "Results location: $RESULTS_DIR"
        log_info "Summary report: $RESULTS_DIR/summary.txt"
    fi
}

# Handle interrupts
trap 'log_error "Benchmark interrupted!"; exit 130' INT TERM

# Run main
main "$@"
