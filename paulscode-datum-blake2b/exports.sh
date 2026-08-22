#!/bin/bash

# Datum Gateway BLAKE2b exports.
#
# Static IPs for this app's three containers. 10.21.21.63-64 and 10.21.22.63 sit
# next to the node app's .62 and clear of the official apps (bitcoin-knots
# 10.21.21.7, lightning 10.21.21.9, electrs 10.21.21.10, mempool 10.21.21.26-28,
# electrs-liquid 10.21.21.50, agent-wallet 10.21.21.60, forktower 10.21.21.61,
# fulcrum 10.21.21.200, mempool-bip110 10.21.21.240-242).

export APP_DATUM_BLAKE2B_GATEWAY_IP="10.21.21.63"
export APP_DATUM_BLAKE2B_CAPTURE_IP="10.21.21.64"
export APP_DATUM_BLAKE2B_REPORT_IP="10.21.22.63"

# Stratum, published on the host so miners on the LAN can reach it. 23334 is the
# official Datum app's port and is deliberately left to it, so both can be
# installed on the same server. 23335 is skipped for the same reason it is
# skipped on StartOS: nothing uses it there, but keeping one number for one
# purpose across both platforms is worth more than reclaiming it.
export APP_DATUM_BLAKE2B_STRATUM_PORT="23336"

# The opt-in compatibility-test port. Same mining, with the conversation recorded.
export APP_DATUM_BLAKE2B_CAPTURE_PORT="23337"
