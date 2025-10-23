#!/bin/bash
# Stop elbencho services on all client nodes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

echo "Stopping elbencho services on all clients..."
echo "Clients: $CLIENT_HOSTS"
echo ""

for host in $CLIENT_HOSTS; do
    echo "Stopping service on $host..."
    ssh "$host" "pkill -f 'elbencho --service' || true"
done

echo ""
echo "All services stopped."
