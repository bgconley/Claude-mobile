# Weka.io Storage Cluster Benchmark Suite (elbencho)

A comprehensive benchmark suite for testing and showcasing the high throughput and low latency capabilities of Weka.io storage clusters using elbencho.

## Overview

This benchmark suite uses [elbencho](https://github.com/breuner/elbencho) in distributed mode to measure storage performance across multiple client nodes, all accessing a shared Weka filesystem mount point.

### What Gets Tested

1. **High Throughput Tests**
   - Sequential write throughput
   - Sequential read throughput
   - Parallel write throughput (multiple files)
   - Parallel read throughput (multiple files)

2. **Low Latency Tests**
   - Random write latency (small block I/O)
   - Random read latency (small block I/O)
   - Mixed workload (70% read, 30% write)

3. **Metadata Performance**
   - File creation operations
   - File stat operations
   - File deletion operations

## Prerequisites

### Software Requirements

- **elbencho**: Must be installed on all client nodes
  ```bash
  # Installation example (adjust for your distribution)
  git clone https://github.com/breuner/elbencho.git
  cd elbencho
  make -j
  sudo make install
  ```

- **SSH**: Passwordless SSH access from master to all clients
  ```bash
  # Option 1: Use the automated setup script (recommended)
  bash scripts/setup-passwordless-ssh.sh

  # Option 2: Manual setup
  ssh-keygen
  ssh-copy-id user@client1
  ssh-copy-id user@client2
  # etc.
  ```

  **Note**: The benchmark scripts automatically check for passwordless SSH connectivity before running tests. If SSH is not properly configured, you'll receive a clear error message with instructions to fix it.

### Weka Requirements

- Weka filesystem mounted on all client nodes at the same mount point
- Sufficient space in the Weka filesystem for test files
- Write permissions to create test directories

### System Requirements

- Multiple client nodes (recommended: 3 or more)
- Network connectivity between all clients
- One node designated as the "master" coordinator

## Setup

### 1. Clone this repository on the master node

```bash
git clone <repository-url>
cd elbencho-weka-benchmarks
```

### 2. Configure your cluster

Edit `configs/cluster.conf` to match your environment:

```bash
# List all client hostnames/IPs
CLIENT_HOSTS="client1 client2 client3"

# Designate the master node (must be in CLIENT_HOSTS)
MASTER_HOST="client1"

# Weka mount point (must be identical on all clients)
WEKA_MOUNT="/mnt/weka"

# Adjust other parameters as needed
THROUGHPUT_FILE_SIZE="10G"
THROUGHPUT_THREADS=16
LATENCY_THREADS=8
# ... etc
```

### 3. Verify setup

```bash
# Check that all clients are accessible
bash scripts/check-services.sh

# Verify Weka mount exists
ls -la /mnt/weka  # (or your configured WEKA_MOUNT)
```

## Running Benchmarks

### Run All Benchmarks (Recommended)

```bash
# Make scripts executable
chmod +x *.sh scripts/*.sh

# Run the complete benchmark suite
./run-all-benchmarks.sh
```

This will:
1. Run all 8 benchmark tests sequentially
2. Save results to `results/run_TIMESTAMP/`
3. Generate a summary report

### Run Individual Tests

```bash
# Run a single test by number
./run-single-test.sh <test-number>

# Examples:
./run-single-test.sh 1  # Sequential Write Throughput
./run-single-test.sh 5  # Random Write Latency
./run-single-test.sh 7  # Mixed Workload
```

Available tests:
- 1: Sequential Write Throughput
- 2: Sequential Read Throughput
- 3: Parallel Write Throughput
- 4: Parallel Read Throughput
- 5: Random Write Latency
- 6: Random Read Latency
- 7: Mixed Workload
- 8: Metadata Operations

### Manual Test Execution

You can also run individual test scripts directly:

```bash
# Create a results directory
mkdir -p results/manual-test

# Run specific test
bash scripts/01-sequential-write-throughput.sh results/manual-test

# Generate report
bash scripts/generate-report.sh results/manual-test
```

## Understanding Results

### Throughput Metrics

Throughput is measured in **MiB/s** or **GiB/s**:
- Higher is better
- Sequential tests typically show maximum throughput
- Parallel tests show scalability with multiple files/threads

### Latency Metrics

Latency is measured in **microseconds (µs)** or **milliseconds (ms)**:
- Lower is better
- Key metrics:
  - `min`: Minimum latency
  - `avg`: Average latency
  - `p50`: Median (50th percentile)
  - `p90`: 90th percentile
  - `p99`: 99th percentile
  - `max`: Maximum latency

### IOPS Metrics

IOPS (I/O Operations Per Second):
- Higher is better
- More relevant for small block I/O (4K, 8K)
- Key indicator of latency performance

### Sample Output

```
WRITE:           15234.56 MiB/s       123456 IOPS
READ:            18456.78 MiB/s       156789 IOPS

Latency:
  avg:  245.67 µs
  p50:  198.34 µs
  p90:  456.78 µs
  p99:  892.45 µs
```

## Results Structure

```
results/
├── run_20250123_143045/          # Full benchmark suite run
│   ├── cluster.conf              # Configuration snapshot
│   ├── summary.txt               # Generated summary report
│   ├── sequential-write-throughput.txt
│   ├── sequential-read-throughput.txt
│   ├── parallel-write-throughput.txt
│   ├── parallel-read-throughput.txt
│   ├── random-write-latency.txt
│   ├── random-read-latency.txt
│   ├── mixed-workload.txt
│   └── metadata-operations.txt
└── single-test_20250123_150000/  # Single test run
    ├── cluster.conf
    └── sequential-write-throughput.txt
```

## Customization

### Adjust Test Parameters

Edit `configs/cluster.conf`:

```bash
# File sizes
THROUGHPUT_FILE_SIZE="20G"  # Larger for longer tests
LATENCY_FILE_SIZE="2G"      # Adjust for latency tests

# Block sizes
THROUGHPUT_BLOCK_SIZE="2M"  # Larger = more throughput
LATENCY_BLOCK_SIZE="4K"     # Smaller = latency focus

# Thread counts
THROUGHPUT_THREADS=32       # More threads = more load
LATENCY_THREADS=16

# Files per thread
FILES_PER_THREAD=200        # More files = more metadata load

# Direct I/O
USE_DIRECT_IO=1             # 1=bypass cache, 0=use cache
```

### Create Custom Tests

Create a new script in `scripts/`:

```bash
#!/bin/bash
# Custom test script

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

RESULTS_DIR="${1:-results/latest}"
# ... your test logic here ...

# Run elbencho with your parameters
elbencho \
    --hosts "$SERVICE_HOSTS" \
    --threads 8 \
    --size "1G" \
    --block "64K" \
    # ... other flags ...
    "$TEST_DIR"
```

## Utility Scripts

### SSH Setup

```bash
# Automated passwordless SSH setup (interactive)
bash scripts/setup-passwordless-ssh.sh

# This script will:
# - Check for existing SSH keys (or generate new ones)
# - Copy keys to all client nodes
# - Verify connectivity
# - Check elbencho installation on all clients
# - Verify Weka mount on all clients
```

### Service Management

```bash
# Start services on all clients (background)
bash scripts/start-services.sh

# Check service status
bash scripts/check-services.sh

# Stop all services
bash scripts/stop-services.sh
```

### Report Generation

```bash
# Generate report from existing results
bash scripts/generate-report.sh results/run_20250123_143045
```

## Troubleshooting

### SSH Connection Issues

If you get SSH connection errors when running benchmarks:

```bash
# Option 1: Use the automated setup script (recommended)
bash scripts/setup-passwordless-ssh.sh

# Option 2: Manual troubleshooting
# Test SSH connectivity
for host in client1 client2 client3; do
    ssh $host "echo OK from $host"
done

# If passwords are still being requested, copy your SSH key:
ssh-copy-id client1
ssh-copy-id client2
# etc.
```

The benchmark suite will automatically detect SSH configuration issues and provide helpful error messages with instructions.

### elbencho Not Found

```bash
# Check installation
which elbencho

# Add to PATH if needed
export PATH=$PATH:/path/to/elbencho
```

### Service Won't Start

```bash
# Check if port is available (default: 8765)
ssh client1 "netstat -ln | grep 8765"

# Kill existing services
bash scripts/stop-services.sh

# Try manual start
ssh client1 "elbencho --service --foreground"
```

### Permission Denied on Weka Mount

```bash
# Check mount permissions
ls -la /mnt/weka

# Check if mounted
mount | grep weka

# Check write access
touch /mnt/weka/test && rm /mnt/weka/test
```

### Out of Space

```bash
# Check Weka capacity
df -h /mnt/weka

# Reduce test file sizes in configs/cluster.conf
THROUGHPUT_FILE_SIZE="5G"  # Reduced from 10G
```

## Best Practices

1. **Run on Idle System**: For accurate results, run benchmarks when the Weka cluster is not under other load

2. **Multiple Runs**: Run tests multiple times and average results for consistency

3. **Warm-up**: Consider running a quick warm-up test before collecting final results

4. **Clean Environment**: Ensure test directories are clean before running
   ```bash
   rm -rf /mnt/weka/elbencho-test/*
   ```

5. **Monitor Resources**: Watch system resources during tests
   ```bash
   # On each client
   htop
   iostat -x 1
   ```

6. **Document Environment**: Save cluster configuration and system specs with results

## Architecture

### How It Works

1. **Master Node**: Coordinates the benchmark, sends commands to service nodes
2. **Service Nodes**: Run elbencho in service mode, execute I/O operations
3. **Shared Storage**: All nodes access the same Weka mount point
4. **Local Execution**: Each node performs I/O to its local mount (which is the same shared filesystem)

### elbencho Flow

```
Master Node                    Service Nodes (client1, client2, client3)
    |                                |           |           |
    |--- Start Services ------------->|---------->|---------->|
    |                                |           |           |
    |--- Send Test Config ----------->|---------->|---------->|
    |                                |           |           |
    |                          [Perform I/O to /mnt/weka]
    |                                |           |           |
    |<-- Aggregate Results -----------|<----------|<----------|
    |                                |           |           |
    |--- Stop Services -------------->|---------->|---------->|
```

## Performance Expectations

With a well-configured Weka cluster, you can expect:

- **Sequential Throughput**: 10-40+ GB/s (depends on cluster size and network)
- **Random Read Latency**: < 1ms (often sub-millisecond)
- **Random Write Latency**: < 2ms
- **Metadata Operations**: 100k+ ops/sec
- **IOPS**: 1M+ (with enough clients and small blocks)

## References

- [elbencho GitHub](https://github.com/breuner/elbencho)
- [elbencho Documentation](https://github.com/breuner/elbencho/blob/master/README.md)
- [Weka.io Documentation](https://docs.weka.io)

## Contributing

Feel free to submit issues or pull requests to improve this benchmark suite.

## License

This benchmark suite is provided as-is for testing Weka.io storage clusters.
