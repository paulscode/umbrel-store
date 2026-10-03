#!/bin/bash

# Mempool Pruned exports.
# Static IPs for this app's three containers. The BIP-110 Mempool sits on
# .240-.242 and this takes the next block, so the two explorers can be installed
# together: they share no address, no port and no database.

export APP_MEMPOOL_PRUNED_IP="10.21.21.243"
export APP_MEMPOOL_PRUNED_PORT="8080"
export APP_MEMPOOL_PRUNED_API_IP="10.21.21.244"
export APP_MEMPOOL_PRUNED_DB_IP="10.21.21.245"

# Lightning Fork, when it is installed. Its read-only macaroon and TLS
# certificate are mounted into the api container, which reads the Lightning
# network graph over its REST port for the explorer's Lightning pages.
# umbrelOS only injects the env of an app's required dependencies, and
# Lightning Fork is not required, so its address is written out here
# (paulscode-lightning-fork/exports.sh: APP_LIGHTNING_FORK_NODE_IP and
# APP_LIGHTNING_FORK_NODE_REST_PORT).
#
# Docker creates a missing bind-mount source, as root, so with Lightning Fork
# absent the mount points at an empty directory of this app's own rather than
# at Lightning Fork's: a root-owned app-data directory left behind for an app
# that is not installed would get in the way of installing it later.
#
# Installed is not the same as usable. The api container also checks that this
# explorer's node is on the BLAKE2b chain and that Lightning Fork has a wallet,
# and leaves the Lightning pages off otherwise; see docker-compose.yml.
mempool_pruned_lnd_dir="$(dirname "${EXPORTS_APP_DIR:-/nonexistent/x}" 2>/dev/null || true)/paulscode-lightning-fork/data/lnd"
if [ -d "${mempool_pruned_lnd_dir}" ]; then
  export APP_MEMPOOL_PRUNED_LIGHTNING_FORK="true"
  export APP_MEMPOOL_PRUNED_LND_DIR="${mempool_pruned_lnd_dir}"
else
  export APP_MEMPOOL_PRUNED_LIGHTNING_FORK="false"
  export APP_MEMPOOL_PRUNED_LND_DIR="${EXPORTS_APP_DIR:-/nonexistent}/data/no-lightning"
fi
unset mempool_pruned_lnd_dir
export APP_MEMPOOL_PRUNED_LND_REST_URL="https://10.21.21.66:8180"
