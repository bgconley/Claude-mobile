#!/bin/bash
# Common functions for all benchmark scripts
# Source this file in your scripts: source "$SCRIPT_DIR/scripts/common-functions.sh"

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

# Start elbencho service on a host with error handling
start_service_on_host() {
    local host=$1
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$host" "elbencho --service --foreground" &>/dev/null &
        then
            sleep 1
            # Verify service started
            if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "pgrep -f 'elbencho --service' > /dev/null" 2>/dev/null; then
                return 0
            fi
        else
            log_warning "Failed to start service on $host (attempt $((retry_count + 1))/$max_retries)"

            # Check if it's an SSH issue
            if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "exit" 2>/dev/null; then
                log_error "SSH connection to $host failed"
                log_error "Please ensure passwordless SSH is configured: ssh-copy-id $host"
                return 1
            fi
        fi

        ((retry_count++))
        sleep 2
    done

    log_error "Failed to start elbencho service on $host after $max_retries attempts"
    return 1
}

# Start services on all clients with error handling
start_all_services() {
    log_info "Starting elbencho services on all clients..."

    local failed_hosts=""
    local success_count=0

    for host in $CLIENT_HOSTS; do
        echo -n "  Starting service on $host... "

        if start_service_on_host "$host"; then
            echo -e "${GREEN}OK${NC}"
            ((success_count++))
        else
            echo -e "${RED}FAILED${NC}"
            failed_hosts="$failed_hosts $host"
        fi
    done

    if [ -n "$failed_hosts" ]; then
        log_error "Failed to start services on:$failed_hosts"
        log_error "Stopping any running services and exiting..."
        stop_all_services
        exit 1
    fi

    log_success "Started services on all $success_count clients"
    sleep 3
}

# Stop elbencho service on a host with error handling
stop_service_on_host() {
    local host=$1

    if ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" "pkill -f 'elbencho --service'" 2>/dev/null; then
        return 0
    else
        # Check if service was running
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "pgrep -f 'elbencho --service' > /dev/null" 2>/dev/null; then
            return 1  # Service still running, failed to stop
        else
            return 0  # Service not running, that's fine
        fi
    fi
}

# Stop services on all clients
stop_all_services() {
    log_info "Stopping elbencho services on all clients..."

    for host in $CLIENT_HOSTS; do
        echo -n "  Stopping service on $host... "

        if stop_service_on_host "$host"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}WARNING${NC}"
        fi
    done
}

# Cleanup function to ensure services are stopped on exit
cleanup_services() {
    echo ""
    log_info "Cleaning up services..."
    stop_all_services
}

# Check if a command succeeded, with helpful error message
check_command_status() {
    local status=$1
    local error_msg=$2

    if [ $status -ne 0 ]; then
        log_error "$error_msg"
        log_error "Exit code: $status"

        # Try to provide helpful hints
        if [ $status -eq 127 ]; then
            log_error "Command not found. Is elbencho installed on all clients?"
        elif [ $status -eq 255 ]; then
            log_error "SSH connection failed. Check network connectivity and SSH configuration."
        fi

        return 1
    fi

    return 0
}

# Run elbencho with error handling
run_elbencho() {
    local description=$1
    shift
    local args=("$@")

    log_info "Running elbencho: $description"

    # Run elbencho and capture exit status
    elbencho "${args[@]}"
    local status=$?

    if ! check_command_status $status "elbencho command failed"; then
        log_error "Command was: elbencho ${args[*]}"
        cleanup_services
        exit 1
    fi

    return 0
}
