#!/bin/bash
# Generate Summary Report from Benchmark Results

set -e

RESULTS_DIR="${1:-results/latest}"
SUMMARY_FILE="${RESULTS_DIR}/summary.txt"

echo "Generating summary report..."
echo ""

# Create summary file
cat > "$SUMMARY_FILE" << 'EOF'
================================================================
  WEKA STORAGE CLUSTER BENCHMARK SUMMARY
================================================================

EOF

# Add configuration info
echo "CONFIGURATION:" >> "$SUMMARY_FILE"
cat "${RESULTS_DIR}/cluster.conf" | grep -E "CLIENT_HOSTS|WEKA_MOUNT|NUM_CLIENTS" >> "$SUMMARY_FILE" || true
echo "" >> "$SUMMARY_FILE"

# Add timestamp
echo "Benchmark Date: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Function to extract key metrics
extract_metrics() {
    local file=$1
    local test_name=$2

    if [ ! -f "$file" ]; then
        echo "  [MISSING] $test_name" >> "$SUMMARY_FILE"
        return
    fi

    echo "================================================================" >> "$SUMMARY_FILE"
    echo "$test_name" >> "$SUMMARY_FILE"
    echo "================================================================" >> "$SUMMARY_FILE"

    # Extract throughput if available
    if grep -q "MiB/s" "$file"; then
        echo "THROUGHPUT:" >> "$SUMMARY_FILE"
        grep -E "WRITE.*MiB/s|READ.*MiB/s" "$file" | head -5 >> "$SUMMARY_FILE" || true
        echo "" >> "$SUMMARY_FILE"
    fi

    # Extract IOPS if available
    if grep -q "IOPS" "$file"; then
        echo "IOPS:" >> "$SUMMARY_FILE"
        grep -E "WRITE.*IOPS|READ.*IOPS" "$file" | head -5 >> "$SUMMARY_FILE" || true
        echo "" >> "$SUMMARY_FILE"
    fi

    # Extract latency if available
    if grep -q "latency" "$file" || grep -q "LAT" "$file"; then
        echo "LATENCY:" >> "$SUMMARY_FILE"
        grep -E "lat|LAT|latency" "$file" | grep -E "avg|min|max|p50|p90|p99" | head -10 >> "$SUMMARY_FILE" || true
        echo "" >> "$SUMMARY_FILE"
    fi

    echo "" >> "$SUMMARY_FILE"
}

# Extract metrics from each test
extract_metrics "${RESULTS_DIR}/sequential-write-throughput.txt" "1. SEQUENTIAL WRITE THROUGHPUT"
extract_metrics "${RESULTS_DIR}/sequential-read-throughput.txt" "2. SEQUENTIAL READ THROUGHPUT"
extract_metrics "${RESULTS_DIR}/parallel-write-throughput.txt" "3. PARALLEL WRITE THROUGHPUT"
extract_metrics "${RESULTS_DIR}/parallel-read-throughput.txt" "4. PARALLEL READ THROUGHPUT"
extract_metrics "${RESULTS_DIR}/random-write-latency.txt" "5. RANDOM WRITE LATENCY"
extract_metrics "${RESULTS_DIR}/random-read-latency.txt" "6. RANDOM READ LATENCY"
extract_metrics "${RESULTS_DIR}/mixed-workload.txt" "7. MIXED WORKLOAD (70/30 R/W)"
extract_metrics "${RESULTS_DIR}/metadata-operations.txt" "8. METADATA OPERATIONS"

# Add footer
cat >> "$SUMMARY_FILE" << 'EOF'
================================================================
  END OF SUMMARY REPORT
================================================================

For detailed results, see individual test output files in:
EOF

echo "$RESULTS_DIR" >> "$SUMMARY_FILE"

# Display summary
cat "$SUMMARY_FILE"

echo ""
echo "Summary report saved to: $SUMMARY_FILE"
