#!/bin/bash

# Fulcrum Pruned exports.
# Static IP addresses for this app's containers on Umbrel's Docker network, plus the
# Electrum endpoint other apps can depend on. Clear of the official apps (lndg holds
# 10.21.21.75) and of this store (Electrs Pruned is .70/.71 and 10.21.22.70; the
# BLAKE2b and SHA256 apps hold .62-.68, .72 and 10.21.22.62-.73).
# Keep this file to plain export lines: it runs under strict mode on the host.

export APP_FULCRUM_PRUNED_WEB_IP="10.21.22.74"
export APP_FULCRUM_PRUNED_SERVER_IP="10.21.21.74"
export APP_FULCRUM_PRUNED_PROXY_IP="10.21.21.76"

# Electrum protocol port (plaintext TCP) on the internal network.
# Dependent apps connect to ${SERVER_IP}:${SERVER_PORT}.
export APP_FULCRUM_PRUNED_SERVER_PORT="50001"

# The block-fetching proxy's RPC port: a bitcoind-compatible endpoint that also
# answers for blocks the node has dropped.
export APP_FULCRUM_PRUNED_PROXY_PORT="8332"

# Offered as an implementation of paulscode-electrs-pruned (umbrel-app.yml), so an app depending on
# Electrs Pruned can select this server instead. It serves the same Electrum protocol versions,
# 1.8 on the BLAKE2b chain included, and has a block-fetching proxy at the same kind of address.
# `:=`, not plain assignment: when the user selected Electrs Pruned itself, its exports are the
# ones that count, and these fill only what is still unset.
for var in SERVER_IP SERVER_PORT PROXY_IP PROXY_PORT WEB_IP; do
    electrs_var="APP_ELECTRS_PRUNED_${var}"
    fulcrum_var="APP_FULCRUM_PRUNED_${var}"
    export "$electrs_var"="${!electrs_var:=${!fulcrum_var}}"
done
