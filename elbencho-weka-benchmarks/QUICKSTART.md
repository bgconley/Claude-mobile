# Quick Start Guide

## 5-Minute Setup

### 1. Prerequisites Check

```bash
# Verify elbencho is installed
elbencho --version

# Verify SSH access to all clients
ssh client1 hostname
ssh client2 hostname
ssh client3 hostname

# Verify Weka mount
ls -la /mnt/weka
```

**If passwordless SSH is not set up:**
```bash
# Use the automated setup script (easiest)
bash scripts/setup-passwordless-ssh.sh
```

### 2. Configure

```bash
# Edit cluster configuration
nano configs/cluster.conf

# Update these lines:
CLIENT_HOSTS="client1 client2 client3"  # Your actual hostnames
MASTER_HOST="client1"                    # Your master node
WEKA_MOUNT="/mnt/weka"                   # Your Weka mount point
```

### 3. Run

```bash
# Make scripts executable
chmod +x *.sh scripts/*.sh

# Run all benchmarks
./run-all-benchmarks.sh

# Or run a single test
./run-single-test.sh 1  # Sequential write throughput
```

### 4. View Results

```bash
# Results are saved to results/run_TIMESTAMP/
ls -la results/

# View summary
cat results/run_*/summary.txt

# View detailed results
less results/run_*/sequential-write-throughput.txt
```

## Common Commands

```bash
# Setup passwordless SSH (first time only)
bash scripts/setup-passwordless-ssh.sh

# Run full benchmark suite
./run-all-benchmarks.sh

# Run single test
./run-single-test.sh <1-8>

# Start services manually
bash scripts/start-services.sh

# Check service status
bash scripts/check-services.sh

# Stop services
bash scripts/stop-services.sh

# Generate report from existing results
bash scripts/generate-report.sh results/run_20250123_143045
```

## Test Numbers

- 1: Sequential Write Throughput
- 2: Sequential Read Throughput
- 3: Parallel Write Throughput
- 4: Parallel Read Throughput
- 5: Random Write Latency
- 6: Random Read Latency
- 7: Mixed Workload
- 8: Metadata Operations

## Typical Runtime

- Full suite: ~30-60 minutes (depends on configuration)
- Single test: ~2-10 minutes

## Quick Troubleshooting

**SSH fails**: Set up passwordless SSH
```bash
# Automated setup (recommended)
bash scripts/setup-passwordless-ssh.sh

# Or manual setup
ssh-keygen
ssh-copy-id client1
```

**elbencho not found**: Install or add to PATH
```bash
export PATH=$PATH:/path/to/elbencho
```

**Permission denied**: Check Weka mount permissions
```bash
touch /mnt/weka/test && rm /mnt/weka/test
```

**Service won't start**: Kill existing services
```bash
bash scripts/stop-services.sh
```

## Example Configuration

For a 3-node setup with 100GB of test data:

```bash
CLIENT_HOSTS="weka-client01 weka-client02 weka-client03"
MASTER_HOST="weka-client01"
WEKA_MOUNT="/mnt/weka"
THROUGHPUT_FILE_SIZE="10G"
THROUGHPUT_THREADS=16
LATENCY_THREADS=8
```

## What You'll See

Expected performance (varies by cluster):
- Write throughput: 10-40 GB/s
- Read throughput: 15-50 GB/s
- Random read latency: 200-1000 µs
- Random write latency: 500-2000 µs
- IOPS: 100k-1M+

## Next Steps

- See README.md for detailed documentation
- Customize tests in configs/cluster.conf
- Review individual test results in results/ directory
- Share results with your team!
