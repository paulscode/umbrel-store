#!/bin/bash

# Datum Gateway BLAKE2b exports.
#
# umbreld sources this file under `set -euo pipefail`, and it sources it for
# every app that depends on this one as well as for this one, so a single command
# that exits non-zero takes down this app and its dependents during an update with
# no message. There is nothing here that can fail, and it should stay that way.

# The gateway's container. 10.21.21.63 sits next to the node app's .62 and clear
# of the official apps (bitcoin-knots 10.21.21.7, lightning 10.21.21.9, electrs
# 10.21.21.10, mempool 10.21.21.26-28, electrs-liquid 10.21.21.50, agent-wallet
# 10.21.21.60, fulcrum 10.21.21.200, mempool-bip110 10.21.21.240-242).
#
# .61 is not free even though forktower has been removed from this store:
# anyone who installed it still has it running there. Do not reuse it.
#
# Two more used to be here, for the compatibility-capture proxy and the page that
# turned a capture into a report. Both are gone, along with the capture port
# 23337 and the host-IP lookup that page needed.
export APP_DATUM_BLAKE2B_GATEWAY_IP="10.21.21.63"

# Stratum, published on the host so miners on the LAN can reach it. 23334 is the
# official Datum app's port and is deliberately left to it, so both can be
# installed on the same server. 23335 is skipped for the same reason it is
# skipped on StartOS: nothing uses it there, but keeping one number for one
# purpose across both platforms is worth more than reclaiming it.
export APP_DATUM_BLAKE2B_STRATUM_PORT="23336"
