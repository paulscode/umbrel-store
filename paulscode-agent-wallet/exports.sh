#!/bin/bash

# Agent Wallet exports.
#
# Static IP for this app's container on Umbrel's Docker network, plus optional
# wiring to a local Mempool explorer if one is installed. 10.21.21.60 is in the
# high end of the range to avoid colliding with the official apps (electrs
# 10.21.21.10, fulcrum 10.21.21.200, mempool 10.21.21.26-28, electrs-liquid
# 10.21.21.50, paulscode-mempool-bip110 10.21.21.240-242).

export APP_AGENT_WALLET_IP="10.21.21.60"

# Mempool is OPTIONAL for Agent Wallet (it falls back to the public mempool.space
# API and the local indexer for fees). umbrelOS only injects the env of an app's
# *required* dependencies, so we detect an installed Mempool here (host-side) and
# point the wallet at it — the same pattern the official Mempool app uses to
# optionally wire to Lightning. We set two things per Mempool flavor:
#   *_MEMPOOL_API      - the backend API (internal docker IP, port 8999) used for
#                        fee estimates / chain data.
#   *_MEMPOOL_EXPLORER - the browser-facing web UI used for the dashboard's
#                        clickable explorer links. The internal API IP is NOT
#                        browser-reachable, so this is the LAN URL
#                        (http://<device>.local:<app-port>); DEVICE_DOMAIN_NAME is
#                        provided by Umbrel before this file is sourced. Web UI
#                        ports: official Mempool 3006, Mempool BIP-110 3026.
# Both the official Mempool and the Mempool BIP-110 fork serve their backend API
# on :8999. When no Mempool is installed, neither var is set and the app uses the
# public mempool.space API + explorer.
installed="$("${UMBREL_ROOT}/scripts/app" ls-installed 2>/dev/null | tr ' ' '\n' || true)"
device="${DEVICE_DOMAIN_NAME:-umbrel.local}"
if echo "${installed}" | grep -qxF "mempool"; then
  export APP_AGENT_WALLET_MEMPOOL_API="http://10.21.21.27:8999"
  export APP_AGENT_WALLET_MEMPOOL_EXPLORER="http://${device}:3006"
elif echo "${installed}" | grep -qxF "paulscode-mempool-bip110"; then
  export APP_AGENT_WALLET_MEMPOOL_API="http://10.21.21.241:8999"
  export APP_AGENT_WALLET_MEMPOOL_EXPLORER="http://${device}:3026"
fi

# Electrs Liquid is OPTIONAL — only used when both Anonymize and Liquid are
# enabled (AGENT_WALLET_ANONYMIZE + AGENT_WALLET_LIQUID). Same rationale as
# Mempool above: umbrelOS only injects the env of an app's *required*
# dependencies, and we do NOT want to force-install a ~115 GB heavyweight, so we
# detect it host-side and export its known static Electrum endpoint (the same
# values Electrs Liquid publishes in its own exports.sh: NODE_IP 10.21.21.50,
# NODE_PORT 50001). When it isn't installed, the vars stay empty and the Liquid
# hop is simply unavailable. The compose reads these as ${..:-} defaults.
if echo "${installed}" | grep -qxF "paulscode-electrs-liquid"; then
  export APP_ELECTRS_LIQUID_ELECTRS_NODE_IP="10.21.21.50"
  export APP_ELECTRS_LIQUID_ELECTRS_NODE_PORT="50001"
fi
