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
