#!/bin/bash

# Datum Gateway (SHA256) exports.
#
# umbreld sources this under `set -euo pipefail`, for this app and for anything
# depending on it, so nothing here may exit non-zero. There is nothing that can
# fail, and it should stay that way.

# The gateway's container. 10.21.21.65 sits next to the SHA256 node's .64 and
# clear of the BLAKE2b pair (.62/.63) and the official apps.
export APP_DATUM_SHA256_GATEWAY_IP="10.21.21.65"

# Stratum, published on the host for miners on your LAN. The official Datum app
# keeps 23334 and the BLAKE2b companion 23336, so this takes 23338: 23337 was the
# BLAKE2b app's compatibility-capture port before that feature was removed, and
# reusing a number that appears in its docs under a different meaning is a
# confusion not worth saving a port for.
export APP_DATUM_SHA256_STRATUM_PORT="23338"
