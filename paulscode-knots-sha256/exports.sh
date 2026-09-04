#!/bin/bash

# Bitcoin Knots (SHA256) Companion exports.
#
# READ THIS BEFORE EDITING. umbreld sources this file from `app-script` under
# `set -euo pipefail`, and it sources it for every app that depends on this one
# as well as for this one. A single command that exits non-zero here takes down
# this app and every dependent, during an update, with no message. Guard every
# read, and put `|| true` behind anything that can fail.

# Static IPs for this app's containers. 10.21.21.64 / 10.21.22.64-65 sit clear of
# the official apps (bitcoin-knots 10.21.21.7 with tor .12 and i2pd .13), of the
# BLAKE2b companion (10.21.21.62, 10.21.22.62-63), and of everything else in this
# store.
export APP_KNOTS_SHA256_NODE_IP="10.21.21.64"
export APP_KNOTS_SHA256_TOR_PROXY_IP="10.21.22.64"
export APP_KNOTS_SHA256_I2P_DAEMON_IP="10.21.22.65"

# Ports. The official Bitcoin Knots app takes 9332/9333/9335 and the BLAKE2b
# companion takes 18443/18444/18445, so this takes the 19xxx range. All three can
# be installed at once, which is the point of a companion.
export APP_KNOTS_SHA256_RPC_PORT="19332"
export APP_KNOTS_SHA256_P2P_PORT="19333"
# A second inbound P2P listener granting whitelisted permissions (whitebind).
# An indexer pulling whole historical blocks needs it: on the plain port it is
# subject to inbound eviction and, on a pruned node, to NODE_NETWORK_LIMITED,
# which disconnects it for asking about a block more than 288 deep. For trusted
# internal apps only; deliberately not published to the host.
export APP_KNOTS_SHA256_P2P_WHITEBIND_PORT="19335"
export APP_KNOTS_SHA256_TOR_PORT="19334"
export APP_KNOTS_SHA256_ZMQ_RAWBLOCK_PORT="49332"
export APP_KNOTS_SHA256_ZMQ_RAWTX_PORT="49333"
export APP_KNOTS_SHA256_ZMQ_HASHBLOCK_PORT="49334"
export APP_KNOTS_SHA256_ZMQ_SEQUENCE_PORT="49335"
export APP_KNOTS_SHA256_ZMQ_HASHTX_PORT="49336"

# The bitcoind data directory, as the host sees it. Dependents mount it read-only
# to read the RPC cookie.
#
# `data/bitcoin`, matching the official apps' layout, because this app is new and
# has no existing installs to keep in place. The BLAKE2b companion uses `data`
# instead, and that is not an inconsistency to tidy up: that app has had its chain
# there since it shipped, and moving it would mean asking every install to
# relocate gigabytes of blocks.
export APP_KNOTS_SHA256_DATA_DIR="${EXPORTS_APP_DIR}/data/bitcoin"

# One chain, and it is the same chain the official Bitcoin and Bitcoin Knots apps
# follow. This node's whole difference is that it never enforces BIP-110.
export APP_KNOTS_SHA256_NETWORK="mainnet"
export APP_KNOTS_SHA256_NETWORK_ELECTRS="bitcoin"

# ---------------------------------------------------------------------------
# RPC credentials.
#
# Generated once, on first run, and kept in this app's own .env. The node writes
# an `rpcauth=` line from them, which means it ALSO still writes its `.cookie`:
# bitcoind only skips the cookie when `rpcpassword` is set, and this sets neither
# `rpcpassword` nor `rpcuser`. So dependents that authenticate by cookie work
# unchanged, and the connect modal has real credentials to show.
BITCOIN_ENV_FILE="${EXPORTS_APP_DIR}/.env"

if [[ ! -f "${BITCOIN_ENV_FILE}" ]]; then
	if [[ -z ${BITCOIN_RPC_USER+x} ]] || [[ -z ${BITCOIN_RPC_PASS+x} ]]; then
		BITCOIN_RPC_USER="umbrel"
		BITCOIN_RPC_DETAILS=$("${EXPORTS_APP_DIR}/scripts/rpcauth.py" "${BITCOIN_RPC_USER}")
		BITCOIN_RPC_PASS=$(echo "$BITCOIN_RPC_DETAILS" | tail -1)
	fi

	echo "export APP_KNOTS_SHA256_RPC_USER='${BITCOIN_RPC_USER}'"	>> "${BITCOIN_ENV_FILE}"
	echo "export APP_KNOTS_SHA256_RPC_PASS='${BITCOIN_RPC_PASS}'"	>> "${BITCOIN_ENV_FILE}"
fi

# shellcheck disable=SC1090
. "${BITCOIN_ENV_FILE}"

# Tor hidden services, for the connect modal. `2>/dev/null || echo` because these
# files do not exist until Tor has published, which is minutes after a fresh
# install, and a bare `cat` on a missing file would abort this whole script.
rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-rpc/hostname"
p2p_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-p2p/hostname"
export APP_KNOTS_SHA256_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"
export APP_KNOTS_SHA256_P2P_HIDDEN_SERVICE="$(cat "${p2p_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"

# ---------------------------------------------------------------------------
# Offered as an implementation of `bitcoin`, so any app that depends on a Bitcoin
# node can select this one from Umbrel's own picker.
#
# Unlike the BLAKE2b companion, which carries a long warning here because it
# follows a different chain, this one follows the same chain as the official
# apps. An app pointed at it reads the same blocks and the same transactions it
# would read from your primary node, so selecting it is not a correctness
# hazard.
#
# Two things to know before selecting it anyway:
#
#   - It is pruned by default. An app that needs deep history should use an
#     archival node, or you should turn pruning off in this one's settings.
#   - It never enforces BIP-110. That is the reason it exists, and it only
#     becomes visible if the network splits over that rule, at which point this
#     node and an enforcing one would follow different chains. Point each app at
#     the one whose chain it should follow.
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
    sha256_var="APP_KNOTS_SHA256_${var}"
    if [ -n "${!sha256_var-}" ]; then
        export "$bitcoin_var"="${!bitcoin_var:=${!sha256_var}}"
    fi
done
