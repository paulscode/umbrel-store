#!/bin/bash

# Bitcoin Knots BLAKE2b exports.
#
# READ THIS BEFORE EDITING. umbreld sources this file from `app-script` under
# `set -euo pipefail`, and it sources it for every app that depends on this one as
# well as for this one. A single command that exits non-zero here takes down this
# app and every dependent, during an update, with no message. That has happened:
# a `sed` on a file that did not exist yet exited 2, `pipefail` carried it through
# `head`, and an update removed this app's containers, failed `post-patch-update`,
# and left the app stopped along with a dependent stuck part way through
# installing. Guard every read, and put `|| true` behind anything that can fail.

# Static IPs for this app's containers. 10.21.21.62 / 10.21.22.62-63 sit above
# .61, which forktower held before it was removed from this store and which
# existing installs still hold, and clear of the official apps (bitcoin-knots 10.21.21.7,
# lightning 10.21.21.9, electrs 10.21.21.10, mempool 10.21.21.26-28,
# electrs-liquid 10.21.21.50, agent-wallet 10.21.21.60, fulcrum 10.21.21.200,
# mempool-bip110 10.21.21.240-242).
#
# NODE_IP keeps the address it has always had. Dependents carry it as a fallback
# default, so moving it would silently point them at nothing.
export APP_KNOTS_BLAKE2B_NODE_IP="10.21.21.62"
export APP_KNOTS_BLAKE2B_TOR_PROXY_IP="10.21.22.62"
export APP_KNOTS_BLAKE2B_I2P_DAEMON_IP="10.21.22.63"

# Ports. These are bitcoind's regtest defaults, inherited from when this app ran a
# private chain, and kept because they are the contract dependents resolve.
export APP_KNOTS_BLAKE2B_RPC_PORT="18443"
export APP_KNOTS_BLAKE2B_P2P_PORT="18444"
# A second inbound P2P listener granting whitelisted permissions (whitebind).
# An indexer pulling whole historical blocks needs it: on the plain port it is
# subject to inbound eviction and, on a pruned node, to NODE_NETWORK_LIMITED,
# which disconnects it for asking about a block more than 288 deep. For trusted
# internal apps only; deliberately not published to the host.
export APP_KNOTS_BLAKE2B_P2P_WHITEBIND_PORT="18445"
export APP_KNOTS_BLAKE2B_TOR_PORT="18334"
export APP_KNOTS_BLAKE2B_ZMQ_RAWBLOCK_PORT="48342"
export APP_KNOTS_BLAKE2B_ZMQ_RAWTX_PORT="48343"
export APP_KNOTS_BLAKE2B_ZMQ_HASHBLOCK_PORT="48344"
export APP_KNOTS_BLAKE2B_ZMQ_SEQUENCE_PORT="48345"
export APP_KNOTS_BLAKE2B_ZMQ_HASHTX_PORT="48346"

# The bitcoind data directory, as the host sees it. Dependents mount it read-only
# to read the RPC cookie.
#
# `data` rather than `data/bitcoin`, which is where the official Bitcoin apps put
# it. That is deliberate: this app's chain data has been at `data` since it
# shipped, and the node app reads BITCOIN_DIR from its environment, so it is
# pointed at the existing directory rather than moving ~5 GB of blocks to match a
# convention. See docker-compose.yml.
export APP_KNOTS_BLAKE2B_DATA_DIR="${EXPORTS_APP_DIR}/data"

# One chain. BLAKE2b activated on mainnet at block 961640 on 2026-08-30, and this
# app follows that chain and nothing else. It used to read a chain out of a
# settings file written by the gateway app's page; both are gone.
export APP_KNOTS_BLAKE2B_NETWORK="mainnet"
export APP_KNOTS_BLAKE2B_NETWORK_ELECTRS="bitcoin"

# ---------------------------------------------------------------------------
# RPC credentials.
#
# Generated once, on first run, and kept in this app's own .env. The node writes
# an `rpcauth=` line from them, which means it ALSO still writes its `.cookie`:
# bitcoind only skips the cookie when `rpcpassword` is set, and this sets neither
# `rpcpassword` nor `rpcuser`. So dependents that authenticate by cookie keep
# working unchanged, and the connect modal in the node's own UI has real
# credentials to show.
#
# Same shape as the official Bitcoin Knots app, including generating the salted
# hash with its `rpcauth.py`.
BITCOIN_ENV_FILE="${EXPORTS_APP_DIR}/.env"

if [[ ! -f "${BITCOIN_ENV_FILE}" ]]; then
	if [[ -z ${BITCOIN_RPC_USER+x} ]] || [[ -z ${BITCOIN_RPC_PASS+x} ]]; then
		BITCOIN_RPC_USER="umbrel"
		BITCOIN_RPC_DETAILS=$("${EXPORTS_APP_DIR}/scripts/rpcauth.py" "${BITCOIN_RPC_USER}")
		BITCOIN_RPC_PASS=$(echo "$BITCOIN_RPC_DETAILS" | tail -1)
	fi

	echo "export APP_KNOTS_BLAKE2B_RPC_USER='${BITCOIN_RPC_USER}'"	>> "${BITCOIN_ENV_FILE}"
	echo "export APP_KNOTS_BLAKE2B_RPC_PASS='${BITCOIN_RPC_PASS}'"	>> "${BITCOIN_ENV_FILE}"
fi

# shellcheck disable=SC1090
. "${BITCOIN_ENV_FILE}"

# Tor hidden services, for the connect modal. `2>/dev/null || echo` because these
# files do not exist until Tor has published, which is minutes after a fresh
# install, and a bare `cat` on a missing file would abort this whole script.
rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-rpc/hostname"
p2p_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-p2p/hostname"
export APP_KNOTS_BLAKE2B_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"
export APP_KNOTS_BLAKE2B_P2P_HIDDEN_SERVICE="$(cat "${p2p_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"

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
# `:=` and not plain assignment: umbreld sets APP_BITCOIN_* from the
# implementation the user actually selected, and this only fills what is still
# unset. Overwriting would let this node answer for a dependent that chose a
# different one.
for var in \
    NODE_IP \
    TOR_PROXY_IP \
    I2P_DAEMON_IP \
    DATA_DIR \
    RPC_PORT \
    P2P_PORT \
    P2P_WHITEBIND_PORT \
    TOR_PORT \
    ZMQ_RAWBLOCK_PORT \
    ZMQ_RAWTX_PORT \
    ZMQ_HASHBLOCK_PORT \
    ZMQ_SEQUENCE_PORT \
    ZMQ_HASHTX_PORT \
    NETWORK \
    RPC_USER \
    RPC_PASS \
    RPC_HIDDEN_SERVICE \
    P2P_HIDDEN_SERVICE \
    NETWORK_ELECTRS
do
    bitcoin_var="APP_BITCOIN_${var}"
    blake2b_var="APP_KNOTS_BLAKE2B_${var}"
    if [ -n "${!blake2b_var-}" ]; then
        export "$bitcoin_var"="${!bitcoin_var:=${!blake2b_var}}"
    fi
done
