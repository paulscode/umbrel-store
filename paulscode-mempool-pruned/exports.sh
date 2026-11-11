#!/bin/bash

# Mempool Pruned exports.
# Static IPs for this app's three containers. The BIP-110 Mempool sits on
# .240-.242 and this takes the next block, so the two explorers can be installed
# together: they share no address, no port and no database.

export APP_MEMPOOL_PRUNED_IP="10.21.21.243"
export APP_MEMPOOL_PRUNED_PORT="8080"
export APP_MEMPOOL_PRUNED_API_IP="10.21.21.244"
export APP_MEMPOOL_PRUNED_DB_IP="10.21.21.245"

# A Lightning node, when one is installed. Its read-only macaroon and TLS
# certificate are mounted into the api container, which reads the Lightning
# network graph over its REST port for the explorer's Lightning pages.
#
# Two are known, one per chain, and which one is used is decided by the chain
# this explorer's node is on, in the api container (see docker-compose.yml):
#
#   Lightning Fork (paulscode-lightning-fork)   the BLAKE2b chain
#   Lightning Node (lightning, the official LND) the SHA256 chain
#
# umbrelOS only injects the env of an app's required dependencies, and neither
# is required, so their addresses are written out here
# (paulscode-lightning-fork/exports.sh: APP_LIGHTNING_FORK_NODE_IP and
# APP_LIGHTNING_FORK_NODE_REST_PORT; getumbrel/umbrel-apps lightning/exports.sh:
# APP_LIGHTNING_NODE_IP and APP_LIGHTNING_NODE_REST_PORT). Each one's TLS
# certificate names its address, so the api verifies it as it stands.
#
# Core Lightning is not offered. Mempool reads it over its RPC socket only, and
# whether this app's user can open the official app's socket was not something
# that could be checked.
#
# Docker creates a missing bind-mount source, as root, so with a Lightning app
# absent its mount points at an empty directory of this app's own rather than
# at the other app's: a root-owned app-data directory left behind for an app
# that is not installed would get in the way of installing it later.
#
# Installed is not the same as usable. The api container also checks which
# chain this explorer's node is on and that the Lightning node for that chain
# has a wallet, and leaves the Lightning pages off otherwise.
mempool_pruned_apps_dir="$(dirname "${EXPORTS_APP_DIR:-/nonexistent/x}" 2>/dev/null || true)"
mempool_pruned_no_lightning="${EXPORTS_APP_DIR:-/nonexistent}/data/no-lightning"
export APP_MEMPOOL_PRUNED_LIGHTNING="false"

mempool_pruned_lnd_dir="${mempool_pruned_apps_dir}/paulscode-lightning-fork/data/lnd"
if [ -d "${mempool_pruned_lnd_dir}" ]; then
  export APP_MEMPOOL_PRUNED_LIGHTNING="true"
  export APP_MEMPOOL_PRUNED_FORK_LND_DIR="${mempool_pruned_lnd_dir}"
else
  export APP_MEMPOOL_PRUNED_FORK_LND_DIR="${mempool_pruned_no_lightning}"
fi
export APP_MEMPOOL_PRUNED_FORK_LND_REST_URL="https://10.21.21.66:8180"

mempool_pruned_lnd_dir="${mempool_pruned_apps_dir}/lightning/data/lnd"
if [ -d "${mempool_pruned_lnd_dir}" ]; then
  export APP_MEMPOOL_PRUNED_LIGHTNING="true"
  export APP_MEMPOOL_PRUNED_OFFICIAL_LND_DIR="${mempool_pruned_lnd_dir}"
else
  export APP_MEMPOOL_PRUNED_OFFICIAL_LND_DIR="${mempool_pruned_no_lightning}"
fi
export APP_MEMPOOL_PRUNED_OFFICIAL_LND_REST_URL="https://10.21.21.9:8080"

unset mempool_pruned_apps_dir mempool_pruned_no_lightning mempool_pruned_lnd_dir
