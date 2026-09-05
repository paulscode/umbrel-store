#!/bin/bash

# Electrs Pruned exports.
# Static IP addresses for this app's containers on Umbrel's Docker network, plus
# the Electrum endpoint other apps can depend on. The high end of the 10.21.x.x
# range, to stay clear of the official apps: the Bitcoin Node is 10.21.21.8 and
# the official Electrs app uses 10.21.21.10 and 10.21.22.4. Within this store,
# .50 is electrs-liquid and .60 to .64 are agent-wallet, the blake2b apps and
# .61, which forktower held before it was removed from this store and which
# existing installs still hold. So this takes .70.

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
# Which node this app indexes is Umbrel's choice, not ours.
#
# `dependencies: [bitcoin]` in umbrel-app.yml makes Umbrel offer every installed app
# declaring `implements: [bitcoin]` and set APP_BITCOIN_* from the one selected. That
# now includes Knots (BLAKE2b) Companion, so the BLAKE2b chain is reachable through
# the same picker as every other node rather than through a second selector of ours.
#
# This app therefore reads APP_BITCOIN_* directly and resolves nothing itself. An
# earlier version served its own settings page for this, written before Umbrel's
# alternatives mechanism was found; it is gone, and the native picker is the one
# place the choice is made.
#
# The p2p port is the whitebind one where the selected node publishes it. 18444-style
# ordinary listeners are shared with inbound peers, where a connection earns no
# permissions and can be evicted to seat another; the whitebind listener grants noban
# and download. electrs does not reconnect its p2p connection, so an eviction ends the
# process, and under a busy wallet that is a restart loop.
export APP_ELECTRS_PRUNED_BACKEND_P2P_PORT="${APP_BITCOIN_P2P_WHITEBIND_PORT:-${APP_BITCOIN_P2P_PORT}}"
