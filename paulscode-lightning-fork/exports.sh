#!/bin/bash

# Lightning Fork exports.
#
# READ THIS BEFORE EDITING. umbreld sources this file under `set -euo pipefail`,
# for this app and for every app that depends on it. One command exiting
# non-zero here stops the app with no message. Guard every read, and put
# `|| true` behind anything that can fail.

# Static IPs, clear of the official Lightning Node app (10.21.21.9 and
# 10.21.22.3) and of this store's other apps (.60 to .65 and .70 to .71 on
# both subnets).
export APP_LIGHTNING_FORK_IP="10.21.22.66"        # the dashboard
export APP_LIGHTNING_FORK_NODE_IP="10.21.21.66"   # lnd
export APP_LIGHTNING_FORK_STATUS_IP="10.21.22.67" # the tile's front door

# Ports. The official Lightning Node app holds 9735, 10009 and 8080 on the
# host, so this app takes 9737, 10010 and 8180, and listens on those same
# numbers inside its containers: what the connect modal shows is what a
# wallet dials.
export APP_LIGHTNING_FORK_NODE_PORT="9737"
export APP_LIGHTNING_FORK_NODE_GRPC_PORT="10010"
export APP_LIGHTNING_FORK_NODE_REST_PORT="8180"
# The watchtower, when turned on in Advanced Settings, for an address other
# than its own Tor onion. Published as 9913, which the official Lightning app
# does not take, onto LND's default 9911 inside: moving the listener would
# change the port in a running tower's onion URI and strand its clients.
export APP_LIGHTNING_FORK_WATCHTOWER_PORT="9913"
# The companion app's API, served by the dashboard on a TLS port of its own
# (umbrelOS puts plain HTTP on the LAN and its own login in front of the
# tile's port), and over a hidden service of its own.
export APP_LIGHTNING_FORK_MOBILE_PORT="7157"
# The server's LAN IP, which the dashboard offers phones beside its .local
# name (not every phone resolves .local). Empty if it can't be read here.
APP_LIGHTNING_FORK_LAN_IP="$(ip route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -n 1 || true)"
export APP_LIGHTNING_FORK_LAN_IP
export APP_LIGHTNING_FORK_NODE_DATA_DIR="${EXPORTS_APP_DIR}/data/lnd"

# ---------------------------------------------------------------------------
# The Mempool apps are OPTIONAL: the dashboard can take its fee rates (the
# Low, Medium and High the app's page shows) and its transaction links from
# one. umbrelOS only injects the env of an app's required dependencies, so an
# installed Mempool app is detected here, host-side, the way the official
# Mempool app detects Lightning. For each: the app's web UI on the app
# network (its nginx serves the fee endpoint the page reads) for the
# dashboard's own requests, the UI's port on this host for the links a
# browser follows, and its onion address for a page opened over Tor.
#
# Both Mempool Pruned and the official Mempool are offered. Which chain an
# app follows depends on the Bitcoin node it is connected to, not on the
# app, so the dashboard asks each app for the first BLAKE2b block and will
# not use one on the other chain.
#
# The list of installed apps comes from umbreld's legacy-compat script, which
# is what the official Mempool app uses; umbrelOS 1.x and 2.x ship it, and
# earlier releases had scripts/app instead. As a last resort an app counts as
# installed if its data directory exists. Nothing here may exit non-zero
# (see the top of this file).
lightning_fork_umbrel_root="${UMBREL_ROOT:-/home/umbrel/umbrel}"
lightning_fork_installed="$(/opt/umbreld/source/modules/apps/legacy-compat/app-script ls-installed 2>/dev/null \
  || "${lightning_fork_umbrel_root}/scripts/app" ls-installed 2>/dev/null \
  || true)"
lightning_fork_installed="$(echo "${lightning_fork_installed}" | tr ' ' '\n' || true)"
lightning_fork_app_installed() {
  echo "${lightning_fork_installed}" | grep -qxF "$1" && return 0
  [ -d "${EXPORTS_APP_DIR:-/nonexistent}/../$1" ] && return 0
  return 1
}

if lightning_fork_app_installed "paulscode-mempool-pruned"; then
  export APP_LIGHTNING_FORK_MEMPOOL_PRUNED_API="http://10.21.21.243:8080"
  export APP_LIGHTNING_FORK_MEMPOOL_PRUNED_UI_PORT="3032"
  export APP_LIGHTNING_FORK_MEMPOOL_PRUNED_HIDDEN_SERVICE="$(cat "${EXPORTS_TOR_DATA_DIR:-/nonexistent}/app-paulscode-mempool-pruned/hostname" 2>/dev/null || true)"
fi

if lightning_fork_app_installed "mempool"; then
  export APP_LIGHTNING_FORK_MEMPOOL_API="http://10.21.21.26:3006"
  export APP_LIGHTNING_FORK_MEMPOOL_UI_PORT="3006"
  export APP_LIGHTNING_FORK_MEMPOOL_HIDDEN_SERVICE="$(cat "${EXPORTS_TOR_DATA_DIR:-/nonexistent}/app-mempool/hostname" 2>/dev/null || true)"
fi
# umbreld sources several apps' exports in one shell; leave nothing behind
# for the next one. Prefixed names, so nothing of another app's is touched.
unset -f lightning_fork_app_installed
unset lightning_fork_installed lightning_fork_umbrel_root

# Where the daemon writes its verdict on the selected node
# (chain-identity.json), kept apart from the wallet so the status container
# can read it without being handed the wallet directory.
export APP_LIGHTNING_FORK_STATUS_DIR="${EXPORTS_APP_DIR}/data/status"

# ---------------------------------------------------------------------------
# Which Bitcoin node this app follows is Umbrel's choice, not ours.
#
# `dependencies: [bitcoin]` in umbrel-app.yml makes Umbrel offer every installed
# app that declares `implements: [bitcoin]` and fill APP_BITCOIN_* from the one
# selected. Only a node on the BLAKE2b chain will do, and nothing here can tell
# the chains apart, so nothing here tries: the daemon checks the node at start,
# refuses one it cannot confirm, and the status container shows that verdict
# on the tile.
BIN_ARGS=()
BIN_ARGS+=( "--configfile=/data/.lnd/umbrel-lnd.conf" )
# [Application Options]
BIN_ARGS+=( "--listen=0.0.0.0:${APP_LIGHTNING_FORK_NODE_PORT}" )
BIN_ARGS+=( "--rpclisten=0.0.0.0:${APP_LIGHTNING_FORK_NODE_GRPC_PORT}" )
BIN_ARGS+=( "--restlisten=0.0.0.0:${APP_LIGHTNING_FORK_NODE_REST_PORT}" )

# [Bitcoin]
# One chain. The BLAKE2b chain is a fork of mainnet; there is no test network
# to select. A node reporting another network is refused by the daemon.
BIN_ARGS+=( "--bitcoin.active" )
BIN_ARGS+=( "--bitcoin.mainnet" )
BIN_ARGS+=( "--bitcoin.node=bitcoind" )
BIN_ARGS+=( "--bitcoin.chain-identity-file=/status/chain-identity.json" )
if [[ "${APP_BITCOIN_NETWORK:-mainnet}" != "mainnet" ]]; then
	echo "Warning (${EXPORTS_APP_ID}): the selected Bitcoin node is on '${APP_BITCOIN_NETWORK}', and Lightning Fork follows mainnet only" || true
fi

# [Bitcoind]
BIN_ARGS+=( "--bitcoind.rpchost=${APP_BITCOIN_NODE_IP:-}:${APP_BITCOIN_RPC_PORT:-}" )
BIN_ARGS+=( "--bitcoind.rpcuser=${APP_BITCOIN_RPC_USER:-}" )
BIN_ARGS+=( "--bitcoind.rpcpass=${APP_BITCOIN_RPC_PASS:-}" )

# Block and transaction notifications: ZMQ when the selected node is serving
# it, RPC polling otherwise. A node whose exports name ZMQ ports it does not
# actually serve (a bitcoind built without libzmq does exactly that, and the
# Knots (BLAKE2b) Companion did at 1.1.6) would otherwise stop the daemon at
# start with "connection refused" and nothing on the tile to say why. One TCP
# connect with a one-second limit decides; it is inside an `if`, so it cannot
# abort this file. Polling notices a block within ten seconds, which a
# Lightning node can live with; ZMQ is the better of the two when it is there.
lightning_fork_zmq=0
if [[ -n "${APP_BITCOIN_NODE_IP:-}" ]] && [[ -n "${APP_BITCOIN_ZMQ_RAWBLOCK_PORT:-}" ]]; then
	if timeout 1 bash -c "exec 3<>/dev/tcp/${APP_BITCOIN_NODE_IP}/${APP_BITCOIN_ZMQ_RAWBLOCK_PORT}" 2>/dev/null; then
		lightning_fork_zmq=1
	fi
fi
if [[ "${lightning_fork_zmq}" = 1 ]]; then
	BIN_ARGS+=( "--bitcoind.zmqpubrawblock=tcp://${APP_BITCOIN_NODE_IP}:${APP_BITCOIN_ZMQ_RAWBLOCK_PORT}" )
	BIN_ARGS+=( "--bitcoind.zmqpubrawtx=tcp://${APP_BITCOIN_NODE_IP}:${APP_BITCOIN_ZMQ_RAWTX_PORT:-}" )
	export APP_LIGHTNING_FORK_BLOCK_SOURCE="zmq"
else
	BIN_ARGS+=( "--bitcoind.rpcpolling" )
	BIN_ARGS+=( "--bitcoind.blockpollinginterval=10s" )
	BIN_ARGS+=( "--bitcoind.txpollinginterval=10s" )
	export APP_LIGHTNING_FORK_BLOCK_SOURCE="rpcpolling"
fi

# [tor]
BIN_ARGS+=( "--tor.active" )
BIN_ARGS+=( "--tor.v3" )
BIN_ARGS+=( "--tor.control=${TOR_PROXY_IP:-}:29051" )
BIN_ARGS+=( "--tor.socks=${TOR_PROXY_IP:-}:${TOR_PROXY_PORT:-}" )
BIN_ARGS+=( "--tor.targetipaddress=${APP_LIGHTNING_FORK_NODE_IP}" )
BIN_ARGS+=( "--tor.password=${TOR_PASSWORD:-}" )

export APP_LIGHTNING_FORK_COMMAND=$(IFS=" "; echo "${BIN_ARGS[@]}")

# Tor hidden services, for the connect modal. These files do not exist until
# Tor has published, minutes after a fresh install; a bare `cat` on a missing
# file would abort this whole script.
rest_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-rest/hostname"
grpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-grpc/hostname"
export APP_LIGHTNING_FORK_REST_HIDDEN_SERVICE="$(cat "${rest_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"
export APP_LIGHTNING_FORK_GRPC_HIDDEN_SERVICE="$(cat "${grpc_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"
# Empty until Tor has published it. The dashboard also reads the hostname
# file itself, through a read-only mount of this directory, so it offers
# phones the onion as soon as Tor writes it.
mobile_hidden_service_dir="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-mobile"
mobile_hidden_service_file="${mobile_hidden_service_dir}/hostname"
export APP_LIGHTNING_FORK_MOBILE_HIDDEN_SERVICE="$(cat "${mobile_hidden_service_file}" 2>/dev/null || true)"
# Docker would create a missing mount source as root, and Tor (uid 1000)
# refuses a hidden service directory it does not own, which would take the
# app's Tor down. So make it here first, empty, as Tor wants it: owned by
# 1000 and private. Tor fills it. An existing directory is left alone.
if [[ ! -e "${mobile_hidden_service_dir}" ]] && [[ -d "${EXPORTS_TOR_DATA_DIR:-/nonexistent}" ]]; then
	mkdir -m 700 "${mobile_hidden_service_dir}" 2>/dev/null || true
	chown 1000:1000 "${mobile_hidden_service_dir}" 2>/dev/null || true
fi
unset mobile_hidden_service_dir mobile_hidden_service_file
