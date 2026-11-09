#!/bin/bash

# Frigate (BLAKE2b) Companion exports.
# Static IP addresses for this app's containers on Umbrel's Docker network. Clear of the official
# apps and of this store: Electrs Pruned is .70/.71 and 10.21.22.70, Fulcrum Pruned .74/.76 and
# 10.21.22.74, the BLAKE2b and SHA256 apps hold .62-.68, .72 and 10.21.22.62-.73, and the SHA256
# Frigate companion takes .77. Keep this file to plain export lines: it runs under strict mode on
# the host.

export APP_FRIGATE_BLAKE2B_WEB_IP="10.21.22.78"
export APP_FRIGATE_BLAKE2B_SERVER_IP="10.21.21.78"

# Electrum protocol port (plaintext TCP) on the internal network, Silent Payments included.
export APP_FRIGATE_BLAKE2B_SERVER_PORT="50001"
