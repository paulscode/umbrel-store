#!/bin/bash

# Electrs Liquid exports.
# Static IP addresses for this app's containers on Umbrel's Docker network, plus
# the Electrum endpoint other apps can depend on. Using the high end of the
# 10.21.x.x range to avoid collisions with official apps (e.g. the Bitcoin
# Electrs app uses 10.21.21.10 / 10.21.22.4).

export APP_ELECTRS_LIQUID_ELECTRS_WEB_IP="10.21.22.50"
export APP_ELECTRS_LIQUID_ELECTRS_NODE_IP="10.21.21.50"

# Electrum protocol port (plaintext TCP) served by the indexer on the internal
# network. Dependent apps should connect to ${NODE_IP}:${NODE_PORT}.
export APP_ELECTRS_LIQUID_ELECTRS_NODE_PORT="50001"
