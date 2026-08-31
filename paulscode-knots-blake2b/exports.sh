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

# ---------------------------------------------------------------------------
# Offered as an implementation of `bitcoin`, so any app that depends on a Bitcoin
# node can select this one from Umbrel's own picker rather than each dependent
# inventing its own way to choose.
#
# READ THIS BEFORE SELECTING IT ANYWHERE. This is not another implementation of
# the same chain, the way Knots and Libre Relay are. It follows the BLAKE2b chain,
# which parted from SHA256d in August 2026 and has its own blocks, its own
# difficulty and its own proof of work. An app that assumes it is talking to the
# SHA256d chain will be wrong about everything it reads. It is the right choice
# for a BLAKE2b Electrum server or explorer, and the wrong one for a Lightning
# node, a payment processor, or anything holding value on the other chain.
#
# Two things this genuinely does not provide, so a dependent needing either will
# not work and should not select it:
#   - rpcauth. It authenticates with the cookie it writes itself, so RPC_USER and
#     RPC_PASS are deliberately absent rather than empty-but-present.
#   - ZMQ. The node does not publish it, so anything subscribing will get nothing.

# p2p, and separately the whitebind listener.
#
# 18444 is the ordinary listener, shared with inbound peers, where a connection
# earns no permissions and can be evicted to seat another peer. 18445 is the
# whitebind one, granting noban and download. An indexer pulling whole blocks
# wants the second: electrs, for one, does not reconnect its p2p connection, so a
# single eviction ends the process.
export APP_KNOTS_BLAKE2B_P2P_PORT="18444"
export APP_KNOTS_BLAKE2B_P2P_WHITEBIND_PORT="18445"

# The chain this node is on, in the two spellings dependents use. Read from the
# same settings file the node's own entrypoint reads, so a node switched between
# chains is followed rather than described by a stale constant. Mainnet is the
# default, matching the node's own.
#
# This read must not be able to fail. umbreld sources this file from `app-script`,
# which runs under `set -euo pipefail`, and it sources it for every app that
# depends on this one as well as for this one. The settings file does not exist
# until the node has started once, and `sed` on a missing file exits 2, which
# `pipefail` carries through `head` and `set -e` turns into an abort of the whole
# script. With stderr sent to /dev/null that abort is silent: the observed symptom
# was an update that removed this app's containers, failed `post-patch-update` with
# exit 2 and no message, and left the app stopped, plus any dependent stuck part
# way through installing. Hence the readability guard, and `|| true` behind it so
# that anything else `sed` might object to is still only a missing value.
_kb_settings="${UMBREL_ROOT}/app-data/paulscode-knots-blake2b/config/settings.json"
_kb_chain=""
if [ -r "${_kb_settings}" ]; then
  _kb_chain="$(sed -n 's/.*"chain"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
      "${_kb_settings}" 2>/dev/null | head -1 || true)"
fi
case "$_kb_chain" in
  regtest) export APP_KNOTS_BLAKE2B_NETWORK="regtest"
           export APP_KNOTS_BLAKE2B_NETWORK_ELECTRS="regtest" ;;
  *)       export APP_KNOTS_BLAKE2B_NETWORK="mainnet"
           export APP_KNOTS_BLAKE2B_NETWORK_ELECTRS="bitcoin" ;;
esac
unset _kb_chain _kb_settings

# The alias every `implements: bitcoin` app performs, in the form the official
# ones use. `:=` and not plain assignment: umbreld sets APP_BITCOIN_* from the
# implementation the user actually selected, and this only fills what is still
# unset. Overwriting would let this node answer for a dependent that chose a
# different one.
for var in \
    NODE_IP \
    DATA_DIR \
    RPC_PORT \
    P2P_PORT \
    P2P_WHITEBIND_PORT \
    NETWORK \
    NETWORK_ELECTRS
do
    bitcoin_var="APP_BITCOIN_${var}"
    blake2b_var="APP_KNOTS_BLAKE2B_${var}"
    if [ -n "${!blake2b_var-}" ]; then
        export "$bitcoin_var"="${!bitcoin_var:=${!blake2b_var}}"
    fi
done
