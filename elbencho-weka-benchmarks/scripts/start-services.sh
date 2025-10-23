#!/bin/bash
# Start elbencho services on all client nodes
# This is a utility script for manual testing

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

echo "Starting elbencho services on all clients..."
echo "Clients: $CLIENT_HOSTS"
echo ""

for host in $CLIENT_HOSTS; do
    echo "Starting service on $host..."
    ssh "$host" "nohup elbencho --service --foreground > /tmp/elbencho-service.log 2>&1 &"
    sleep 1
done

echo ""
echo "Services started. Use 'scripts/stop-services.sh' to stop them."
echo "To check status: scripts/check-services.sh"
