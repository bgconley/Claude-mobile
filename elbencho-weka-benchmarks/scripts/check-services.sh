#!/bin/bash
# Check status of elbencho services on all client nodes

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$SCRIPT_DIR/configs/cluster.conf"

echo "Checking elbencho service status on all clients..."
echo ""

for host in $CLIENT_HOSTS; do
    echo -n "$host: "
    if ssh "$host" "pgrep -f 'elbencho --service' > /dev/null"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
done
