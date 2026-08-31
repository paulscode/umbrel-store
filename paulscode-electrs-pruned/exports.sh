#!/bin/bash

# Electrs Pruned exports.
# Static IP addresses for this app's containers on Umbrel's Docker network, plus
# the Electrum endpoint other apps can depend on. The high end of the 10.21.x.x
# range, to stay clear of the official apps: the Bitcoin Node is 10.21.21.8 and
# the official Electrs app uses 10.21.21.10 and 10.21.22.4. Within this store,
# .50 is electrs-liquid and .60 to .64 are agent-wallet, forktower and the
# blake2b apps, so this takes .70.

export APP_ELECTRS_PRUNED_WEB_IP="10.21.22.70"
export APP_ELECTRS_PRUNED_SERVER_IP="10.21.21.70"
export APP_ELECTRS_PRUNED_PROXY_IP="10.21.21.71"

# Electrum protocol port (plaintext TCP) served on the internal network.
# Dependent apps should connect to ${SERVER_IP}:${SERVER_PORT}.
export APP_ELECTRS_PRUNED_SERVER_PORT="50001"

# The block-fetching proxy's RPC port. Exported because it is a working
# bitcoind-compatible RPC endpoint for a pruned node: it answers getblock for
# blocks the node has dropped. Another app wanting that can use it rather than
# running a second proxy.
export APP_ELECTRS_PRUNED_PROXY_PORT="8332"

# ---------------------------------------------------------------------------
# Which node this app indexes.
#
# Umbrel has no per-app settings form, so the choice is written by this app's own
# page to config/settings.json and resolved here, on the host, at app start. That
# is why changing it needs a restart: the addresses below are baked into the
# containers when they start and cannot change under them.
#
# Read with sed rather than jq, which is not guaranteed present on the host. The
# file is written by this app alone and holds one flat object, so a line-oriented
# read of it is sufficient and has no dependency to go missing.
BACKEND="$(sed -n 's/.*"backend"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "${APP_DATA_DIR:-.}/config/settings.json" 2>/dev/null | head -1)"

case "$BACKEND" in
  knots-blake2b)
    # The BLAKE2b companion node. Authenticates with the cookie it writes itself,
    # so there is no user or password to pass, and its data directory is mounted
    # read-only for the proxy to read that cookie.
    #
    # P2P is 18445, not 18444. 18444 is the ordinary listener shared with inbound
    # peers, where a connection earns no permissions and can be evicted to seat
    # another peer; 18445 is the node's whitebind listener, which grants noban and
    # download. electrs does not reconnect its p2p connection, so one eviction is a
    # restart, and under load a restart loop.
    export APP_ELECTRS_PRUNED_BACKEND_ID="knots-blake2b"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_HOST="${APP_KNOTS_BLAKE2B_NODE_IP:-}"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_PORT="${APP_KNOTS_BLAKE2B_RPC_PORT:-18443}"
    export APP_ELECTRS_PRUNED_BACKEND_P2P_HOST="${APP_KNOTS_BLAKE2B_NODE_IP:-}"
    export APP_ELECTRS_PRUNED_BACKEND_P2P_PORT="18445"
    export APP_ELECTRS_PRUNED_BACKEND_DATA_DIR="${APP_KNOTS_BLAKE2B_DATA_DIR:-${UMBREL_ROOT}/app-data/paulscode-knots-blake2b/data}"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_USER=""
    export APP_ELECTRS_PRUNED_BACKEND_RPC_PASS=""
    ;;
  *)
    # The official Bitcoin Node, and the default. It authenticates with rpcauth
    # rather than a cookie, which is why the user and password are carried here and
    # the cookie path is not.
    export APP_ELECTRS_PRUNED_BACKEND_ID="bitcoin"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_HOST="${APP_BITCOIN_NODE_IP:-}"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_PORT="${APP_BITCOIN_RPC_PORT:-8332}"
    export APP_ELECTRS_PRUNED_BACKEND_P2P_HOST="${APP_BITCOIN_NODE_IP:-}"
    export APP_ELECTRS_PRUNED_BACKEND_P2P_PORT="${APP_BITCOIN_P2P_PORT:-8333}"
    export APP_ELECTRS_PRUNED_BACKEND_DATA_DIR="${APP_BITCOIN_DATA_DIR:-${UMBREL_ROOT}/app-data/bitcoin/data}"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_USER="${APP_BITCOIN_RPC_USER:-}"
    export APP_ELECTRS_PRUNED_BACKEND_RPC_PASS="${APP_BITCOIN_RPC_PASS:-}"
    ;;
esac
