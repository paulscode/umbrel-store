#!/bin/bash

# Cesspool Pruned exports.
#
# READ THIS BEFORE EDITING. umbreld sources this file under `set -euo pipefail`,
# for this app and for every app that depends on it. One command exiting
# non-zero here stops the app with no message. Guard every read, and put
# `|| true` behind anything that can fail.

# Static IPs for this app's two containers. Mempool Pruned holds .243 to .245,
# so this takes the next two. Nothing in this store or in the official one
# uses them (checked against getumbrel/umbrel-apps 3a08738, 2026-11-11).
export APP_CESSPOOL_PRUNED_IP="10.21.21.246"          # web: nginx, what the tile opens
export APP_CESSPOOL_PRUNED_PORT="8080"
export APP_CESSPOOL_PRUNED_UPDATER_IP="10.21.21.247"  # updater: grades blocks, renders the site

# A Lightning node, when one is installed. The updater reads the public channel
# graph from it for the Lightning pages: read-only, with the node's read-only
# macaroon and its TLS certificate, or, for Core Lightning, over its socket.
#
# Three are known, and which one is used is decided in the updater container,
# from the chain this app's Bitcoin node is on, because a Lightning node's
# channels exist on one chain only:
#
#   Lightning Fork (paulscode-lightning-fork)      the BLAKE2b chain
#   Lightning Node (lightning, the official LND)   the SHA256 chain
#   Core Lightning (core-lightning)                the SHA256 chain, when LND is absent
#
# umbrelOS only injects the env of an app's required dependencies, and none of
# these is required, so their addresses are written out here
# (paulscode-lightning-fork/exports.sh: APP_LIGHTNING_FORK_NODE_IP and
# APP_LIGHTNING_FORK_NODE_REST_PORT; getumbrel/umbrel-apps lightning/exports.sh:
# APP_LIGHTNING_NODE_IP and APP_LIGHTNING_NODE_REST_PORT). Each LND's TLS
# certificate names its own address, so the updater verifies it as it stands.
#
# Docker creates a missing bind-mount source, as root, so with a Lightning app
# absent its mount points at an empty directory of this app's own rather than
# at the other app's: a root-owned app-data directory left behind for an app
# that is not installed would get in the way of installing it later.
#
# Installed is not the same as usable. The updater also needs the node for its
# chain to have a wallet (there is no macaroon before that), and it looks when
# it starts: restart this app after installing a Lightning app and creating
# its wallet.
cesspool_pruned_apps_dir="$(dirname "${EXPORTS_APP_DIR:-/nonexistent/x}" 2>/dev/null || true)"
cesspool_pruned_no_lightning="${EXPORTS_APP_DIR:-/nonexistent}/data/no-lightning"

cesspool_pruned_ln_dir="${cesspool_pruned_apps_dir}/paulscode-lightning-fork/data/lnd"
if [ -d "${cesspool_pruned_ln_dir}" ]; then
  export APP_CESSPOOL_PRUNED_LN_FORK_DIR="${cesspool_pruned_ln_dir}"
else
  export APP_CESSPOOL_PRUNED_LN_FORK_DIR="${cesspool_pruned_no_lightning}"
fi
export APP_CESSPOOL_PRUNED_LN_FORK_REST_URL="https://10.21.21.66:8180"

cesspool_pruned_ln_dir="${cesspool_pruned_apps_dir}/lightning/data/lnd"
if [ -d "${cesspool_pruned_ln_dir}" ]; then
  export APP_CESSPOOL_PRUNED_LN_LND_DIR="${cesspool_pruned_ln_dir}"
else
  export APP_CESSPOOL_PRUNED_LN_LND_DIR="${cesspool_pruned_no_lightning}"
fi
export APP_CESSPOOL_PRUNED_LN_LND_REST_URL="https://10.21.21.9:8080"

# Core Lightning keeps its socket at bitcoin/lightning-rpc under this directory.
# The official app runs lightningd as root and leaves the socket at
# lightningd's default mode, 0600, so this app, which runs as 1000, is refused
# unless that has been changed. It is mounted and tried all the same.
cesspool_pruned_ln_dir="${cesspool_pruned_apps_dir}/core-lightning/data/lightningd"
if [ -d "${cesspool_pruned_ln_dir}" ]; then
  export APP_CESSPOOL_PRUNED_LN_CLN_DIR="${cesspool_pruned_ln_dir}"
else
  export APP_CESSPOOL_PRUNED_LN_CLN_DIR="${cesspool_pruned_no_lightning}"
fi

# umbreld sources several apps' exports in one shell; leave nothing behind
# for the next one.
unset cesspool_pruned_apps_dir cesspool_pruned_no_lightning cesspool_pruned_ln_dir
