#!/bin/bash

# Bitcoin Knots BLAKE2b exports.
#
# Static IPs for this app's containers, and the things the Datum Gateway BLAKE2b
# app needs in order to talk to this node. 10.21.21.62 / 10.21.22.62 sit next to
# forktower's .61 and clear of the official apps (bitcoin-knots 10.21.21.7,
# lightning 10.21.21.9, electrs 10.21.21.10, mempool 10.21.21.26-28,
# electrs-liquid 10.21.21.50, agent-wallet 10.21.21.60, fulcrum 10.21.21.200,
# mempool-bip110 10.21.21.240-242).

export APP_KNOTS_BLAKE2B_NODE_IP="10.21.21.62"
export APP_KNOTS_BLAKE2B_WEB_IP="10.21.22.62"

# The regtest RPC port, inside the network only. It is deliberately not published
# to the host: this node has no authentication a user configured, it authenticates
# with the cookie file it writes itself, and a chain with no value is still not a
# thing to leave open on a LAN.
export APP_KNOTS_BLAKE2B_RPC_PORT="18443"

# The dependent reads the cookie straight off this app's data directory, the same
# way the StartOS package reads it from a read-only mount of the node's volume.
# No RPC secret is generated, stored or shared by either app.
export APP_KNOTS_BLAKE2B_DATA_DIR="${UMBREL_ROOT}/app-data/paulscode-knots-blake2b/data"

# Consensus-critical, and must be identical on the node and on the gateway that
# builds the activation block's coinbase. Exported here so there is one source of
# truth: the gateway app reads this value rather than carrying its own copy.
#
# An empty value would be worse than a wrong one. It satisfies the node's startup
# check but makes the rule unenforceable, because a substring search for an empty
# needle always matches. Both entrypoints refuse to start on empty.
export APP_KNOTS_BLAKE2B_HEADLINE="BLAKE2b lab 2026-08-21"
