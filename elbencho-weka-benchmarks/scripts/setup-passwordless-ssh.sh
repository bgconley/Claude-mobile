#!/bin/bash
# Setup Passwordless SSH to All Client Nodes
# This script automates SSH key generation and distribution

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_banner() {
    echo "================================================================"
    echo "  Passwordless SSH Setup for Weka Benchmark Suite"
    echo "================================================================"
    echo "  Master: $MASTER_HOST"
    echo "  Clients: $CLIENT_HOSTS"
    echo "  Total Clients: $NUM_CLIENTS"
    echo "================================================================"
    echo ""
}

check_ssh_key() {
    log_info "Checking for existing SSH keys..."

    if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        log_success "SSH public key found: $HOME/.ssh/id_rsa.pub"
        return 0
    elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        log_success "SSH public key found: $HOME/.ssh/id_ed25519.pub"
        return 0
    else
        log_warning "No SSH key found"
        return 1
    fi
}

generate_ssh_key() {
    log_info "Generating new SSH key pair..."

    echo ""
    echo "This will create a new SSH key pair."
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "SSH key generation cancelled"
        exit 1
    fi

    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -C "elbencho-weka-benchmark"

    if [ $? -eq 0 ]; then
        log_success "SSH key pair generated successfully"
    else
        log_error "Failed to generate SSH key pair"
        exit 1
    fi
}

copy_ssh_key() {
    local host=$1

    echo ""
    log_info "Setting up passwordless SSH to: $host"
    echo "  You will be prompted for the password for $host"
    echo ""

    # Try ssh-copy-id first (most reliable)
    if command -v ssh-copy-id &> /dev/null; then
        ssh-copy-id -o StrictHostKeyChecking=no "$host"
    else
        # Fallback method if ssh-copy-id is not available
        log_warning "ssh-copy-id not found, using alternative method..."

        # Get the public key
        if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            PUBKEY=$(cat "$HOME/.ssh/id_rsa.pub")
        elif [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            PUBKEY=$(cat "$HOME/.ssh/id_ed25519.pub")
        else
            log_error "No public key found"
            return 1
        fi

        # Copy the key manually
        ssh -o StrictHostKeyChecking=no "$host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PUBKEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    fi

    if [ $? -eq 0 ]; then
        log_success "SSH key copied to $host"
        return 0
    else
        log_error "Failed to copy SSH key to $host"
        return 1
    fi
}

test_ssh_connection() {
    local host=$1

    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host" "exit" 2>/dev/null; then
        echo -e "  ${host}: ${GREEN}OK${NC} (passwordless SSH working)"
        return 0
    else
        echo -e "  ${host}: ${RED}FAILED${NC} (passwordless SSH not working)"
        return 1
    fi
}

verify_elbencho_on_clients() {
    log_info "Verifying elbencho installation on all clients..."

    local failed=0

    for host in $CLIENT_HOSTS; do
        echo -n "  Checking $host... "
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "command -v elbencho" &>/dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}NOT FOUND${NC}"
            failed=1
        fi
    done

    if [ $failed -eq 1 ]; then
        echo ""
        log_warning "elbencho is not installed on some clients"
        log_warning "Please install elbencho on all client nodes before running benchmarks"
    else
        log_success "elbencho is installed on all clients"
    fi
}

verify_weka_mount_on_clients() {
    log_info "Verifying Weka mount on all clients..."

    local failed=0

    for host in $CLIENT_HOSTS; do
        echo -n "  Checking $host ($WEKA_MOUNT)... "
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "[ -d '$WEKA_MOUNT' ] && exit 0 || exit 1" 2>/dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}NOT FOUND${NC}"
            failed=1
        fi
    done

    if [ $failed -eq 1 ]; then
        echo ""
        log_warning "Weka mount point not found on some clients"
        log_warning "Please ensure $WEKA_MOUNT is mounted on all client nodes"
    else
        log_success "Weka mount verified on all clients"
    fi
}

main() {
    print_banner

    # Check for existing SSH key
    if ! check_ssh_key; then
        generate_ssh_key
    fi

    echo ""
    log_info "Distributing SSH keys to all clients..."
    echo ""

    local failed_hosts=""
    local success_count=0

    # Copy keys to all hosts
    for host in $CLIENT_HOSTS; do
        if copy_ssh_key "$host"; then
            ((success_count++))
        else
            failed_hosts="$failed_hosts $host"
        fi
    done

    # Test all connections
    echo ""
    log_info "Testing passwordless SSH connections..."
    echo ""

    local test_failed=0
    for host in $CLIENT_HOSTS; do
        if ! test_ssh_connection "$host"; then
            test_failed=1
        fi
    done

    echo ""
    echo "================================================================"
    if [ $test_failed -eq 0 ]; then
        log_success "Passwordless SSH setup complete!"
        log_success "Successfully configured $success_count out of $NUM_CLIENTS clients"

        echo ""
        verify_elbencho_on_clients

        echo ""
        verify_weka_mount_on_clients

        echo ""
        log_info "You can now run the benchmarks:"
        echo "  ./run-all-benchmarks.sh"
    else
        log_error "Some SSH connections failed"
        if [ -n "$failed_hosts" ]; then
            log_error "Failed hosts:$failed_hosts"
        fi
        log_error "Please check the errors above and try again"
        exit 1
    fi
    echo "================================================================"
}

# Run main
main "$@"
